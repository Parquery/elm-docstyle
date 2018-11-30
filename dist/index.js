#!/usr/bin/env node

const Elm = require("./checker.js");
const fs = require("fs");
const minimist = require('minimist');
const path = require('path');

const helpStr =
    `Usages:
$ elm-docstyle [elm_code_directory | path_to_elm_file]
# Docstyle the project and log messages to the console.

Options:
    --help, -h          Print the help output.
    --version, -v       Print the package version.
    --verbose           If set, the offending comments are added to the error report in full.
    --check_all         If set, the checker goes through all declarations; otherwise, only through exported ones.
    --config_path       Path to the elm-docstyle JSON config. If unspecified, a default config is used.
    --format            Output format for CLI. Defaults to "human". Options "human"|"json".`;


const args = minimist(process.argv.slice(2), {
    alias: {
        help: 'h',
        version: 'v'
    },
    boolean: ['help', 'version', 'verbose', 'check_all'],
    string: ['config_path']
});

(function () {
    const elmDocstyleVersion = require(path.join(__dirname, '../', 'package.json')).version;
    if (args.help) {
        console.log(helpStr);
        process.exit(1);
    }

    if (args._.length === 0) {
        console.log("Please specify at least one directory or path to Elm source file.\n");
        console.log(helpStr);
        process.exit(1);
    }

    if (args.version) {
        console.log(elmDocstyleVersion);
        process.exit(0);
    }

    const validFormats = ['json', 'human'];

    var excludedChecks = [];

    if (args.config_path !== undefined) {
        try {
            const txt = fs.readFileSync(args.config_path, 'utf8');

            const excluded = (JSON.parse(txt)).excludedChecks;
            if (excluded === undefined || (excluded instanceof Array) === false
                || (excluded.length > 0 && (typeof excluded[0] !== "string"))) {
                console.log("the provided config path does not contain a valid elm-docstyle configuration.");
                console.log("Please refer to the README to see how a correct config file is shaped.");
                process.exit(1);
            }
            excludedChecks = excluded;
        } catch (err) {
            console.log("failed to open the input config_path:");
            console.log(err);
            process.exit(1);
        }
    }

    const checker = Elm.Main.worker({
        format: validFormats.indexOf(args.format) !== -1 ? args.format : 'human'
        , verbose: args.verbose || false
        , excludedChecks: excludedChecks
        , checkAllDefinitions: args.checkAllDefinitions || false
    });


    var reportList = [];
    checker.ports.outgoing.subscribe(function (newReport) {
        reportList.push(newReport);
    });

    // explore recursively and find all elm files
    var exploreAndSend = function (pth) {
        if (pth.endsWith(".elm")) {
            try {
                const txt = fs.readFileSync(pth, 'utf8');
                checker.ports.incoming.send(txt);
            } catch (err) {
                console.log("failed to open the input path " + pth + ":");
                console.log(err);
                process.exit(1);
            }
        } else if (pth.endsWith("/")) {
            if (pth === "elm-stuff"){
                return
            }
            var paths = [];
            try {
                paths = fs.readdirSync(pth, 'utf8');
            } catch (err) {
                console.log("failed to open the input dir " + pth + ":");
                console.log(err);
                process.exit(1);
            }
            paths.map(path => pth + path).forEach(a => exploreAndSend(a));
        }
    };

    args._.forEach(a => exploreAndSend(a));

    // in milliseconds
    const timeoutStep = 50;

    function finalCheck(roundNr) {
        if (roundNr > 60000 / timeoutStep) {
            console.log("60 seconds have passed and the program did not return. Quitting.");
            process.exit(1);
        }

        if (reportList.length < args._.length) {
            setTimeout(finalCheck, timeoutStep, roundNr++);
            return;
        }
        const errorsReport = reportList.filter(err => err.length > 0);
        if (errorsReport.length === 0) {
            console.log("No issues found! :)");
            process.exit(0);
        } else {
            console.log("Docstyle errors found in " + errorsReport.length + " modules:\n\n");
            errorsReport.sort().forEach(
                function (report) {
                    console.log(report);
                    console.log();
                }
            );
            process.exit(1);
        }
    }

    finalCheck(0);
})();
