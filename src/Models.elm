module Models exposing (Comment, Entity, EntityType(..), Flags, ParsedModule, Verbose)

{-| Provides models for the parsing representation of an Elm module.
-}

import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.Ranged exposing (Ranged)


{-| Describes the top-level definition types.
-}
type EntityType
    = Function (List Parameter)
    | Record (List Field)
    | TypeDef
    | TypeAlias


{-| Is the name of a function parameter.
-}
type alias Parameter =
    String


{-| Is the name of a record field.
-}
type alias Field =
    String


{-| Represents an entity and its associated comment, if it exists.

  - ´range´ -- the lines range covered by the entity (documentation excluded);
  - ´eType´ -- the entity type;
  - ´name´ -- the entity name;
  - ´comment´ -- the documentation associated with the entity, if any;
  - ´exposed´ -- True if the module exposes this entity.

-}
type alias Entity =
    { range : Range
    , eType : EntityType
    , name : String
    , comment : Maybe Comment
    , exposed : Bool
    }


{-| Represents the intermediate representation after parsing a file.

  - ´entities´ -- declarations of types and functions;
  - ´moduleName´ -- the name of the parsed module as it appears on top of the Elm source file;
  - ´topLevelComment´ -- the documentation comment appearing on top of the file, if any;
  - ´otherComments´ -- any comment not belonging to an entity or to the top level definition.

-}
type alias ParsedModule =
    { entities : List Entity
    , moduleName : String
    , topLevelComment : Maybe Comment
    , otherComments : List Comment
    }


{-| Is a comment and the (line, column) range it encompasses.
-}
type alias Comment =
    Ranged String


{-| Is the flag representing verbosity.
-}
type alias Verbose =
    Bool


{-| Contains parsed command line flags.

  - ´verbose´ -- if set, the output of the string format is verbose;
  - ´format´ -- the output format, amongst "human" or "json". If empty, "human" is assumed;
  - ´excludedChecks´ -- contains the checks to be ignored by the checker;
  - ´checkAllDefinitions´ -- if false, the program checks the existence of comments only for
    unexposed type and function definitions; if true, it checks all.

-}
type alias Flags =
    { verbose : Verbose
    , format : String
    , excludedChecks : List String
    , checkAllDefinitions : Bool
    }
