#!/usr/bin/env node

const Elm = require("./checker.js");
const fs = require("fs");
const minimist = require('minimist');
const path = require('path');

const helpStr =
    `Usages:
$ elm-docstyle [elm_code_directory | path_to_elm_file]

Options:
    --help, -h          Print the help output.
    --version, -v       Print the package version.
    --verbose           If set, the offending comments are added to the error report in full.
    --check_all         If set, all the function declarations are checked (including the non-exported ones).
                        Otherwise, only the exported function declarations are checked.
    --config_path       Path to the elm-docstyle JSON config. If unspecified, a default config is used.
    --format            Output format ("human" or "json"). The default is "human".`;


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
        console.log("Please specify at least one directory or path to Elm source file.\n" + helpStr);
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
                console.log("the provided config path does not contain a valid elm-docstyle configuration. " +
                    "Please refer to the README to see how a correct config file is shaped.");
                process.exit(1);
            }
            excludedChecks = excluded;
        } catch (err) {
            console.log("failed to open the input config_path: " + err);
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
                console.log("failed to open the input path " + pth + ": " + err);
                process.exit(1);
            }
        } else {
            if (pth.includes("elm-stuff")) {
                return
            }
            var paths = [];
            try {
                paths = fs.readdirSync(pth, 'utf8');
            } catch (err) {
                if (err.code === "ENOTDIR") {
                    // is not a directory, return
                    return
                } else {
                    console.log("Error while exploring the path " + pth + ": " + err);
                    process.exit(1);
                }
            }

            paths.map(path => pth + "/" + path).forEach(a => exploreAndSend(a));
        }
    };

    args._.forEach(a => exploreAndSend(a));

    // in milliseconds
    const timeoutStep = 50;

    function finalCheck() {
        if (reportList.length < args._.length) {
            setTimeout(finalCheck, timeoutStep);
            return;
        }
        const errorsReport = reportList.filter(err => err.length > 0);
        if (errorsReport.length === 0) {
            console.log("No docstyle issues found! :)");
            process.exit(0);
        } else {
            console.log("Docstyle errors found in " + errorsReport.length + " modules:\n\n");
            errorsReport.sort().forEach(
                function (report) {
                    console.log(report + '\n');
                }
            );
            process.exit(1);
        }
    }

    finalCheck();
})();
