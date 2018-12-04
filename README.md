# elm-docstyle
A tool that allows you to check the existence and quality of your [Elm](http://elm-lang.org/>) code comments.


## Usage

```bash

    elm-docstyle Main.elm  # Perform the docstyle checks on a single file and print the failed checks
    elm-docstyle src/  # Analyze all *.elm files in a directory
    elm-docstyle --format=json src/ # Output the failed checks in JSON
    elm-docstyle --help  # See other command line options
```

## Installation

The following binaries should be available on the path before the installation:

```bash

    node >=6
    elm  0.18.x
```


You can install `elm-docstyle` using `npm`:

```bash

    npm install -g elm-docstyle
```

Alternatively, you can use `yarn`:


```bash

    yarn global add elm-docstyle
```


## Detailed Instructions

``elm-docstyle [elm_code_directory | path_to_elm_file]``

Options:

    --help, -h          Print the help output.
    --version, -v       Print the package version.
    --verbose           If set, the offending comments are added to the error report in full.
    --check_all         If set, all the function declarations are checked (including the non-exported ones).
                        Otherwise, only the exported function declarations are checked.
    --config_path       Path to the elm-docstyle JSON config. If unspecified, a default config is used.
    --format            Output format ("human" or "json"). The default is "human".

Elm-docstyle will check Elm files in all the given directories recursively, excluding the ``elm-stuff``.


## Configuration

You can specify a configuration as a .json file, which needs to contain the fields "excludedChecks" and
"excludedPaths" as list of strings. The excluded checks will be fed to the checker and ignored, and the excluded
files will be skipped when analyzing a directory recursively.

Example of a elm-docstyle.json file:

```json

    {
        "excludedChecks": [
            "TodoComment",
            "NoTopLevelComment"
        ],
        "excludedPaths": [
            "src/DirectoryToIgnore",
            "src/View/FileToIgnore.elm"
        ]
    }
```


Refer to the next section to know which checks are supported (and can hence be disabled).

### Supported Checks

<table>
    <tr>
        <th>Name</th>
        <th>Explanation</th>
    </tr>
    <tr>
        <td>NotCapitalized</td>
        <td>the first word of the comment should be capitalized.</td>
    </tr>
    <tr>
        <td>NoStartingSpace</td>
        <td>the comment should start with a space.</td>
    </tr>
    <tr>
        <td>NoStartingVerb</td>
        <td>the comment should start with a verb in third person singular (stem -s).</td>
    </tr>
    <tr>
        <td>NoEndingPeriod</td>
        <td>the first line of the comment should end with a period.</td>
    </tr>
    <tr>
        <td>EmptyComment</td>
        <td>the comment should contain text apart from newlines and spaces.</td>
    </tr>
    <tr>
        <td>WrongCommentType</td>
        <td>the comment type "{-|-}" should not be used in a non-documentation comment.</td>
    </tr>
    <tr>
        <td>TodoComment</td>
        <td>the comment should not contain the strings (in any capitalization) "TODO" or "FIXME".</td>
    </tr>
    <tr>
        <td>NoEntityComment</td>
        <td>a comment is expected on top of the declaration, but none was found.</td>
    </tr>
    <tr>
        <td>NoTopLevelComment</td>
        <td>a comment is expected for the module, but none was found.</td>
    </tr>
    <tr>
        <td>NotExistingArgument</td>
        <td>the name of a documented argument is not included in the declaration's argument names.</td>
    </tr>
    <tr>
        <td>NotAnnotatedArgument</td>
        <td>the record field or function argument is not included in the documentation.</td>
    </tr>
</table>

We follow the same convention as the Elm core libraries for including arguments in the documentation: specifying
arguments in the format ``- `arg_name` -- explanation`` or ``- `arg_name` &mdash; explanation``, which render nicely in
HTML. Multi-line argument explanations should be indented to match the indentation of the argument name.
For instance:


```elm
    import Models
    import Elm.Syntax.Range 

    {-| Represents an entity and its associated comment, if it exists.

      - ´range´ -- the lines range covered by the entity, excluding the
        documentation;
      - ´eType´ -- the entity type;
      - ´name´ -- the entity name;
      - ´comment´ -- the documentation associated with the entity, if any;
      - ´exposed´ -- True if the module exposes this entity.

    -}
    type alias Entity =
        { range : Elm.Syntax.Range.Range
        , eType : Models.EntityType
        , name : String
        , comment : Maybe Models.Comment
        , exposed : Bool
        }
```

## Issues

If you have feature ideas or checks that you wish to see, please create an issue.
Please check that you do not create duplicate issues or a check for which we
[already have a report](https://github.com/Parquery/elm-docstyle/issues/).

## Development

- Check out the repository.

- In the repository root, run:

```bash
    npm run build
```

to compile the Elm code to ``dist/index.js``.

- Run `npm run prepare` and `npm-install -g` to execute pre-commit checks locally.


## Versioning
We follow [Semantic Versioning](http://semver.org/spec/v1.0.0.html). The version X.Y.Z indicates:

- X is the major version (backward-incompatible),
- Y is the minor version (backward-compatible), and
- Z is the patch version (backward-compatible bug fix).

## Credits

The code representing and parsing the Elm code relies on the excellent
[elm-syntax](https://github.com/stil4m/elm-syntax) package.

The overall structure and "flavor" of the package was inspired by
[elm-format](https://github.com/avh4/elm-format) and 
[elm-analyse](<https://github.com/stil4m/elm-analyse>),
which we also rely on for pre-commit checks.



