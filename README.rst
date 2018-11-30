Elm Docstyle
============
A tool that allows you to check the existence and quality of your `Elm <http://elm-lang.org/>`_ code comments.

Usage
=====

Prerequisites


The following binaries should be available on the path:


.. code-block:: bash

    node >=6
    elm  0.18.x


Installation
============

With ``npm``:

.. code-block:: bash

    npm install -g elm-docstyle

or if using ``yarn``:


.. code-block:: bash

    yarn global add elm-docstyle


Usage
=====

``elm-docstyle [elm_code_directory | path_to_elm_file]``

Options:
    --help, -h          Print the help output.
    --version, -v       Print the package version.
    --verbose           If set, the offending comments are added to the error report in full.
    --check_all         If set, the checker goes through all declarations; otherwise, only through exported ones.
    --config_path       Path to the elm-docstyle JSON config. If unspecified, a default config is used.
    --format            Output format for CLI. Defaults to "human". Options: "human"|"json".

The checker will look recursively for Elm files in all the directories given, excluding the ``elm-stuff``.


Configuration
=============

You can specify a configuration as a .json file, which needs to contain the field "excludedChecks" as a list of
strings. The excluded checks will be fed to the checker and ignored. Example of a elm-docstyle-config.json file:

.. code-block:: JSON

    {
        "excludedChecks": ["TodoComment", "NoTopLevelComment"]
    }



Refer to the next paragraph to know which checks are supported (and can hence be disabled).

Supported Checks
----------------

==========================  ======================================================================================
Check name                  Explanation
==========================  ======================================================================================
``NotCapitalized``          the first word of the comment should be capitalized.
``NoStartingSpace``         the comment should start with a space.
``NoStartingVerb``          the comment should start with a verb in third person (stem -s).
``NoEndingPeriod``          the first line of the comment should end with a period.
``WrongCommentType``        the comment type "{-|-}" should not be used in a non-documentation comment.
``TodoComment``             the comment should not contain the strings (with no dots) "t.o.d.o" or "f.i.x.m.e".
``NoEntityComment``         a comment is expected on top of the declaration, but none was found.
``NoTopLevelComment``       a comment is expected for the module, but none was found.
``NotExistingArgument``     the name of a documented argument is not included in the declaration's argument names.
``NotAnnotatedArgument``    the record field or function argument is not included in the documentation.
==========================  ======================================================================================

We follow the same convention as the Elm core libraries for including arguments in the documentation: specifying
arguments in the format ``* `arg_name` -- explanation`` or ``* `arg_name` &mdash; explanation``, which render nicely in
HTML. For instance:


.. code-block:: elm

    {-| Represents an entity and its associated comment, if it exists.

      * ´range´ -- the lines range covered by the entity (documentation excluded);
      * ´eType´ -- the entity type;
      * ´name´ -- the entity name;
      * ´comment´ -- the documentation associated with the entity, if any;
      * ´exposed´ -- True if the module exposes this entity.

    -}
    type alias Entity =
        { range : Range
        , eType : EntityType
        , name : String
        , comment : Maybe Comment
        , exposed : Bool
        }

Issues
======

If you have feature ideas or checks that you wish to see, please create an issue.
Please check that you do not create duplicate issues or a check for which we
`already have a report <https://github.com/Parquery/elm-docstyle/issues/>`_.

Development
===========

* Check out the repository.

* In the repository root, run:

.. code-block:: bash

    npm run build

to compile the Elm code to ``dist/index.js``.

* Run `npm run prepare` and `npm-install -g` to execute pre-commit checks locally.


Versioning
==========
We follow `Semantic Versioning <http://semver.org/spec/v1.0.0.html>`_. The version X.Y.Z indicates:

* X is the major version (backward-incompatible),
* Y is the minor version (backward-compatible), and
* Z is the patch version (backward-compatible bug fix).

Credits
=======

The code representing and parsing the Elm code relies on the excellent
`elm-syntax <https://github.com/stil4m/elm-syntax>`_ package.

The overall structure and "flavor" of the package was inspired by
`elm-format <https://github.com/avh4/elm-format>`_ and `elm-analyse <https://github.com/stil4m/elm-analyse>`_.



