%{
package parser

import (
	"strings"

	"github.com/sjjian/oracle_sql_parser/ast"
	"github.com/sjjian/oracle_sql_parser/ast/element"
)

func nextQuery(yylex interface{}) string {
	lex := yylex.(*yyLexImpl)
	tc := lex.scanner.TC
	query := string(lex.scanner.Text[lex.lastPos:tc])
	lex.lastPos = tc
	return strings.TrimSpace(query)
}

%}

%union {
    nothing     struct{}
    i           int
    b           bool
    str         string
    node        ast.Node
    anything    interface{}
}

%token <nothing>
    _select
    _from
    _alter
    _table
    _add
    _char
    _byte
    _varchar2
    _nchar
    _nvarchar2
    _number
    _float
    _binaryFloat
    _binaryDouble
    _long
    _raw
    _date
    _timestamp
    _with
    _local
    _time
    _zone
    _interval
    _year
    _to
    _mouth
    _day
    _second
    _blob
    _clob
    _nclob
    _bfile
    _rowid
    _urowid
    _character
    _varying
    _varchar
    _national
    _numeric
    _decimal
    _dec
    _interger
    _int
    _smallInt
    _double
    _precision
    _real
    _collate
    _sort
    _invisible
    _visible
    _encrypt
    _using
    _identified
    _by
    _no
    _salt
    _constraint
    _key
    _not
    _null
    _primary
    _unique
    _references
    _cascade
    _delete
    _on
    _set
    _deferrable
    _deferred
    _immediate
    _initially
    _norely
    _rely
    _is
    _scope
    _default
    _always
    _as
    _generated
    _identity
    _cache
    _cycle
    _increment
    _limit
    _maxvalue
    _minvalue
    _nocache
    _nocycle
    _nomaxvalue
    _nominvalue
    _noorder
    _order
    _start
    _value
    _modify
    _drop
    _decrypt
    _all
    _at
    _column
    _levels
    _substitutable
    _force
    _columns
    _continue
    _unused
    _constraints
    _invalidate
    _online
    _checkpoint
    _rename
    _create
    _blockchain
    _duplicated
    _global
    _immutable
    _private
    _sharded
    _temporary
    _data
    _extended
    _metadata
    _none
    _sharding
    _parent
    _commit
    _definition
    _preserve
    _rows
    _for
    _memoptimize
    _read
    _write

%token <i>
    _intNumber 		"int number"

%token <str>
    _singleQuoteStr 	"single quotes string"
    _doubleQuoteStr 	"double quotes string"
    _nonquotedIdentifier    "nonquoted identifier"

// define type for all structure
%type <i>
    _intNumber
    SortProp
    InvisibleProp
    InvisiblePropOrEmpty
    DropColumnProp
    DropColumnOnline

%type <b>
    IsForce

%type <str>
    _singleQuoteStr
    _doubleQuoteStr
    _nonquotedIdentifier

%type <node>
    EmptyStmt
    Statement 		"all statement"
    AlterTableStmt	"*ast.AlterTableStmt"
    CreateTableStmt

%type <anything>
    StatementList
    TableName
    Identifier
    ColumnName
    Datatype
    OralceBuiltInDataTypes
    CharacterDataTypes
    NumberDataTypes
    LongAndRawDataTypes
    DatetimeDataTypes
    LargeObjectDataTypes
    RowIdDataTypes
    AnsiSupportDataTypes
    ColumnClauses
    ChangeColumnClauseList
    ChangeColumnClause
    RenameColumnClause
    AddColumnClause
    ModifyColumnClause
    ModifyColumnProps
    ModifyColumnProp
    ModifyRealColumnProp
    ModifyColumnVisibilityList
    ModifyColumnVisibility
    ModifyColumnSubstitutable
    RealColumnDef
    ColumnDefList
    ColumnDef
    DropColumnClause
    NumberOrAsterisk
    CollateClauseOrEmpty
    CollateClause
    DefaultCollateClauseOrEmpty
    ColumnNameList
    ColumnNameListForDropColumn
    DropColumnCheckpoint
    DropColumnProps
    DropColumnPropsOrEmpty
    TableDef
    RelTableDef
    RelTablePropsOrEmpty
    RelTableProps
    RelTableProp

%start Start

%%

Start:
    StatementList

StatementList:
    Statement
    {
        if $1 != nil {
            stmt := $1
            stmt.SetText(nextQuery(yylex))
            yylex.(*yyLexImpl).result = append(yylex.(*yyLexImpl).result, stmt)
        }
    }
|   StatementList ';' Statement
    {
        if $3 != nil {
            stmt := $3
            stmt.SetText(nextQuery(yylex))
            yylex.(*yyLexImpl).result = append(yylex.(*yyLexImpl).result, stmt)
        }
    }

Statement:
    EmptyStmt
|   AlterTableStmt
|   CreateTableStmt

EmptyStmt:
    {
        $$ = nil
    }

/* +++++++++++++++++++++++++++++++++++++++++++++ base stmt ++++++++++++++++++++++++++++++++++++++++++++ */

TableName:
    Identifier
    {
    	$$ = &ast.TableName{
	    Table: $1.(*element.Identifier),
	}
    }
|   Identifier '.' Identifier
    {
    	$$ = &ast.TableName{
	    Schema:	$1.(*element.Identifier),
	    Table: 	$3.(*element.Identifier),
	}
    }

ColumnNameList:
    ColumnName
    {
        $$ = []*element.Identifier{$1.(*element.Identifier)}
    }
|   ColumnNameList ',' ColumnName
    {
        $$ = append($1.([]*element.Identifier), $3.(*element.Identifier))
    }

ColumnName:
    Identifier
    {
        $$ = $1
    }

Identifier:
    _nonquotedIdentifier
    {
        $$ = &element.Identifier{
            Typ: element.IdentifierTypeNonQuoted,
            Value: $1,
        }
    }
|   _doubleQuoteStr
    {
        $$ = &element.Identifier{
            Typ: element.IdentifierTypeQuoted,
            Value: $1,
        }
    }

/* +++++++++++++++++++++++++++++++++++++++++++++ alter table ++++++++++++++++++++++++++++++++++++++++++++ */

// see: https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/ALTER-TABLE.html#GUID-552E7373-BF93-477D-9DA3-B2C9386F2877
AlterTableStmt:
    _alter _table TableName MemoptimizeForAlterTable ColumnClauses
    {
        $$ = &ast.AlterTableStmt{
            TableName:      $3.(*ast.TableName),
            ColumnClauses:  $5.([]ast.ColumnClause),
        }
    }

ColumnClauses:
    ChangeColumnClauseList
    {
        $$ = $1
    }
|   RenameColumnClause
    {
        $$ = []ast.ColumnClause{$1.(ast.ColumnClause)}
    }

ChangeColumnClauseList:
    ChangeColumnClause
    {
        $$ = []ast.ColumnClause{$1.(ast.ColumnClause)}
    }
|   ChangeColumnClauseList ChangeColumnClause
    {
        $$ = append($1.([]ast.ColumnClause), $2.(ast.ColumnClause))
    }

ChangeColumnClause:
    AddColumnClause
|   ModifyColumnClause
|   DropColumnClause

/* +++++++++++++++++++++++++++++++++++++++++++++ add column ++++++++++++++++++++++++++++++++++++++++++++ */

AddColumnClause:
    _add '(' ColumnDefList ')' ColumnProps  OutOfLinePartStorageList
    {
        $$ = &ast.AddColumnClause{
	        Columns: $3.([]*ast.ColumnDef),
        }
    }

ColumnProps:
    {
        // TODO
    }

OutOfLinePartStorageList:
    {
        // TODO
    }


ColumnDefList:
    ColumnDef
    {
        $$ = []*ast.ColumnDef{$1.(*ast.ColumnDef)}
    }
|   ColumnDefList ',' ColumnDef
    {
        $$ = append($1.([]*ast.ColumnDef), $3.(*ast.ColumnDef))
    }

ColumnDef:
    RealColumnDef
    {
        $$ = $1
    }
//|   VirtualColumnDef // TODO； support

RealColumnDef:
    ColumnName Datatype CollateClauseOrEmpty SortProp InvisiblePropOrEmpty DefaultOrIdentityClause EncryptClause ColumnDefConstraint
    {
        var collation *ast.Collation
        if $3 != nil {
            collation = $3.(*ast.Collation)
	    }
        props := []ast.ColumnProp{}
        sort := ast.ColumnProp($4)
        if sort != ast.ColumnPropEmpty {
            props = append(props, sort)
        }
        invisible := ast.ColumnProp($5)
        if invisible != ast.ColumnPropEmpty {
            props = append(props, invisible)
        }
        $$ = &ast.ColumnDef{
            ColumnName:         $1.(*element.Identifier),
            Datatype:           $2.(element.Datatype),
            Collation:          collation,
            Props:              props,
        }
    }

CollateClauseOrEmpty:
    {
        $$ = nil
    }
|   CollateClause
    {
        $$ = $1
    }

CollateClause:
    _collate Identifier
    {
        $$ = &ast.Collation{Name: $2.(*element.Identifier)}
    }

SortProp:
    {
        $$ = int(ast.ColumnPropEmpty)
    }
|   _sort
    {
        $$ = int(ast.ColumnPropSort)
    }

InvisiblePropOrEmpty:
    {
        $$ = int(ast.ColumnPropEmpty)
    }
|   InvisibleProp

InvisibleProp:
    _invisible
    {
        $$ = int(ast.ColumnPropInvisible)
    }
|   _visible
    {
        $$ = int(ast.ColumnPropVisible)
    }

DefaultOrIdentityClause:
    {
        // empty
    }
|   DefaultClause
|   IdentityClause

DefaultClause:
    _default Expr
|   _default _no _null Expr

IdentityClause:
    _generated  _as _identity IdentityOptionsOrEmpty
|   _generated _always _as _identity IdentityOptionsOrEmpty
|   _generated _always _as _identity IdentityOptionsOrEmpty
|   _generated _by _default _as _identity IdentityOptionsOrEmpty
|   _generated _by _default _on _null _as _identity IdentityOptionsOrEmpty

IdentityOptionsOrEmpty:
    {
        // empty
    }
|   '(' IdentityOptions ')'

IdentityOptions:
    {
        // empty
    }
|   IdentityOption
|   IdentityOptions IdentityOption

IdentityOption:
    _start _with _intNumber
|   _start _with _limit _value
|   _increment _by _intNumber
|   _maxvalue _intNumber
|   _nomaxvalue
|   _minvalue _intNumber
|   _nominvalue
|   _cycle
|   _nocycle
|   _cache _intNumber
|   _nocache
|   _order
|   _noorder

EncryptClause:
    {
        // empty
    }
|   _encrypt EncryptionSpec

EncryptionSpec:
    EncryptAlgorithm IdentifiedByClause IntergrityAlgorithm SaltProp

EncryptAlgorithm:
    {
        // empty
    }
|   _using _singleQuoteStr

IdentifiedByClause:
    {
        // empty
    }
|   _identified _by Identifier

IntergrityAlgorithm:
    {
        // empty
    }
|   _singleQuoteStr

SaltProp:
    {
        // empty
    }
|   _salt
|   _no _salt

ColumnDefConstraint:
    {
        // empty
    }
|   InlineRefConstraint
|   InlineConstraintList

InlineConstraintList:
    InlineConstraint
|   InlineConstraintList InlineConstraint

/* +++++++++++++++++++++++++++++++++++++++++++++ modify column ++++++++++++++++++++++++++++++++++++++++++++ */

ModifyColumnClause:
    _modify '(' ModifyColumnProps ')'
    {
        $$ = &ast.ModifyColumnClause{
	        Columns: $3.([]*ast.ColumnDef),
        }
    }
|   _modify '(' ModifyColumnVisibilityList ')'
    {
        $$ = &ast.ModifyColumnClause{
	        Columns: $3.([]*ast.ColumnDef),
        }
    }
|   ModifyColumnSubstitutable
    {
        $$ = &ast.ModifyColumnClause{
	        Columns: $1.([]*ast.ColumnDef),
        }
    }

ModifyColumnProps:
    ModifyColumnProp
    {
        $$ = []*ast.ColumnDef{$1.(*ast.ColumnDef)}
    }
|   ModifyColumnProps ',' ModifyColumnProp
    {
        $$ = append($1.([]*ast.ColumnDef), $3.(*ast.ColumnDef))
    }

ModifyColumnProp:
    ModifyRealColumnProp
// |   ModifyVirtualColumnProp // TODO

ModifyRealColumnProp:
    ColumnName Datatype CollateClauseOrEmpty DefaultOrIdentityClauseForModify EncryptClauseForModify ColumnConstraintForModify
    {
        var collation *ast.Collation
        if $3 != nil {
            collation = $3.(*ast.Collation)
	    }
        $$ = &ast.ColumnDef{
            ColumnName:         $1.(*element.Identifier),
            Datatype:           $2.(element.Datatype),
            Collation:          collation,
            Props:              []ast.ColumnProp{},
        }
    }

DefaultOrIdentityClauseForModify:
    _drop _identity
|   DefaultOrIdentityClause

EncryptClauseForModify:
    _decrypt
|   EncryptClause

ColumnConstraintForModify:
    {
        // empty
    }
|   InlineConstraintList

ModifyColumnVisibilityList:
    ModifyColumnVisibility
    {
        $$ = []*ast.ColumnDef{$1.(*ast.ColumnDef)}
    }
|   ModifyColumnVisibilityList ',' ModifyColumnVisibility
    {
        $$ = append($1.([]*ast.ColumnDef), $3.(*ast.ColumnDef))
    }

ModifyColumnVisibility:
    ColumnName InvisibleProp
    {
        $$ = &ast.ColumnDef{
            ColumnName: $1.(*element.Identifier),
            Props:      []ast.ColumnProp{ast.ColumnProp($2)},
        }
    }

ModifyColumnSubstitutable:
    _column ColumnName _substitutable _at _all _levels IsForce
    {
        prop := ast.ColumnPropSubstitutable
        if $7 {
            prop = ast.ColumnPropSubstitutableForce
        }
        $$ = &ast.ColumnDef{
            ColumnName: $2.(*element.Identifier),
            Props:      []ast.ColumnProp{prop},
        }
    }
|   _column ColumnName _not _substitutable _at _all _levels IsForce
    {
        prop := ast.ColumnPropNotSubstitutable
        if $8 {
            prop = ast.ColumnPropNotSubstitutableForce
        }
        $$ = &ast.ColumnDef{
            ColumnName: $2.(*element.Identifier),
            Props:      []ast.ColumnProp{prop},
        }
    }

IsForce:
    {
        $$ = false
    }
|   _force
    {
        $$ = true
    }

/* +++++++++++++++++++++++++++++++++++++++++++++ drop column ++++++++++++++++++++++++++++++++++++++++++++ */

DropColumnClause:
    _set _unused ColumnNameListForDropColumn DropColumnPropsOrEmpty DropColumnOnline
    {
        props := []ast.DropColumnProp{}
        if $4 != nil {
            props = append(props, $4.([]ast.DropColumnProp)...)
        }
        online := ast.DropColumnProp($5)
        if online != ast.DropColumnPropEmpty {
            props = append(props, online)
        }
    	$$ = &ast.DropColumnClause{
            Type:    ast.DropColumnTypeSetUnused,
            Columns: $3.([]*element.Identifier),
            Props:   props,
    	}
    }
|   _drop ColumnNameListForDropColumn DropColumnPropsOrEmpty DropColumnCheckpoint
    {
        props := []ast.DropColumnProp{}
        if $3 != nil {
            props = append(props, $3.([]ast.DropColumnProp)...)
        }
    	cc := &ast.DropColumnClause{
            Type:    ast.DropColumnTypeDrop,
            Columns: $2.([]*element.Identifier),
            Props:   props,
    	}
    	var checkout int
        if $4 != nil {
            checkout = $4.(int)
            cc.CheckPoint = &checkout
        }
        $$ = cc
    }
|   _drop _unused _columns DropColumnCheckpoint
    {
    	cc := &ast.DropColumnClause{
            Type: ast.DropColumnTypeDropUnusedColumns,
    	}
    	var checkout int
        if $4 != nil {
            checkout = $4.(int)
            cc.CheckPoint = &checkout
        }
        $$ = cc
    }
|   _drop _columns _continue DropColumnCheckpoint
    {
    	cc := &ast.DropColumnClause{
            Type: ast.DropColumnTypeDropColumnsContinue,
    	}
    	var checkout int
        if $4 != nil {
            checkout = $4.(int)
            cc.CheckPoint = &checkout
        }
        $$ = cc
    }

ColumnNameListForDropColumn:
    _column ColumnName
    {
        $$ = []*element.Identifier{$2.(*element.Identifier)}
    }
|   '(' ColumnNameList ')'
    {
        $$ = $2
    }

DropColumnPropsOrEmpty:
    {
        $$ = nil
    }
|   DropColumnProps

DropColumnProps:
    DropColumnProp
    {
        $$ = []ast.DropColumnProp{ast.DropColumnProp($1)}
    }
|   DropColumnProps DropColumnProp
    {
        $$ = append($1.([]ast.DropColumnProp), ast.DropColumnProp($2))
    }

DropColumnProp:
    _cascade _constraints
    {
        $$ = int(ast.DropColumnPropCascade)
    }
|   _invalidate
    {
        $$ = int(ast.DropColumnPropInvalidate)
    }

DropColumnOnline:
    {
        $$ = int(ast.DropColumnPropEmpty)
    }
|   _online
    {
        $$ = int(ast.DropColumnPropOnline)
    }

DropColumnCheckpoint:
    {
        $$ = nil
    }
|   _checkpoint _intNumber
    {
        $$ = $2
    }

/* +++++++++++++++++++++++++++++++++++++++++++ rename column +++++++++++++++++++++++++++++++++++++++++ */

RenameColumnClause:
    _rename _column ColumnName _to ColumnName
    {
    	$$ = &ast.RenameColumnClause{
    	    OldName: $3.(*element.Identifier),
    	    NewName: $5.(*element.Identifier),
    	}
    }

/* +++++++++++++++++++++++++++++++++++++++++++ create table ++++++++++++++++++++++++++++++++++++++++++ */

CreateTableStmt:
    _create _table TableType TableName ShardingType TableDef Memoptimize ParentTable
    {
    	$$ = &ast.CreateTableStmt{
            TableName:  $4.(*ast.TableName),
            RelTable:   $6.(*ast.RelTableDef),
    	}
    }

TableType:
    {
        // empty
    }
|   _global _temporary
|   _private _temporary
|   _sharded
|   _duplicated
|   _immutable
|   _blockchain
|   _immutable _blockchain

ShardingType:
    {
        // empty
    }
|   _sharding '=' _metadata
|   _sharding '=' _data
|   _sharding '=' _extended _data
|   _sharding '=' _none

ParentTable:
    {
        // empty
    }
|   _parent TableName

TableDef: // todo: support object table and XML type table
    RelTableDef

RelTableDef:
    RelTablePropsOrEmpty ImmutableTableClauses BlockchainTableClauses DefaultCollateClauseOrEmpty OnCommitClause PhysicalProps TableProps
    {
        rd := &ast.RelTableDef{}
        if $1 != nil {
            rd.Columns = $1.([]*ast.ColumnDef)
        }
        $$ = rd
    }

ImmutableTableClauses:

BlockchainTableClauses:

DefaultCollateClauseOrEmpty:
    {
        $$ = nil
    }
|   _default CollateClause
    {
        $$ = $2
    }

OnCommitClause:
    OnCommitDef OnCommitRows

OnCommitDef:
    {
        // empty
    }
|   _on _commit _drop _definition
|   _on _commit _preserve _definition

OnCommitRows:
    {
        // empty
    }
|   _on _commit _delete _rows
|   _on _commit _preserve _rows

PhysicalProps: // todo

TableProps: // todo

RelTablePropsOrEmpty:
    {
        $$ = nil
    }
|   '(' RelTableProps ')'
    {
        $$ = $2
    }

RelTableProps:
    RelTableProp
    {
        $$ = []*ast.ColumnDef{$1.(*ast.ColumnDef)}
    }
|   RelTableProps ',' RelTableProp
    {
        $$ = append($1.([]*ast.ColumnDef), $3.(*ast.ColumnDef))
    }

RelTableProp:
    ColumnDef

/* +++++++++++++++++++++++++++++++++++++++++++++ datatype ++++++++++++++++++++++++++++++++++++++++++++ */

// see: https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/Data-Types.html#GUID-A3C0D836-BADB-44E5-A5D4-265BA5968483
Datatype:
    OralceBuiltInDataTypes
    {
        $$ = $1
    }
|   AnsiSupportDataTypes
    {
        $$ = $1
    }

NumberOrAsterisk:
    _intNumber
    {
        $$ = &element.NumberOrAsterisk{Number: $1}
    }
|   '*'
    {
        $$ = &element.NumberOrAsterisk{IsAsterisk: true}
    }

OralceBuiltInDataTypes:
    CharacterDataTypes
    {
        $$ = $1
    }
|   NumberDataTypes
    {
        $$ = $1
    }
|   LongAndRawDataTypes
    {
        $$ = $1
    }
|   DatetimeDataTypes
    {
        $$ = $1
    }
|   LargeObjectDataTypes
    {
        $$ = $1
    }
|   RowIdDataTypes
    {
        $$ = $1
    }

CharacterDataTypes:
    _char
    {
        d := &element.Char{}
        d.SetDataDef(element.DataDefChar)
        $$ = d
    }
|   _char '(' _intNumber ')'
    {
        size := $3
        d := &element.Char{Size: &size}
        d.SetDataDef(element.DataDefChar)
        $$ = d
    }
|   _char '(' _intNumber _byte ')'
    {
        size := $3
        d := &element.Char{Size: &size, IsByteSize: true}
        d.SetDataDef(element.DataDefChar)
        $$ = d
    }
|   _char '(' _intNumber _char ')'
    {
        size := $3
        d := &element.Char{Size: &size, IsCharSize: true}
        d.SetDataDef(element.DataDefChar)
        d.SetDataDef(element.DataDefChar)
        $$ = d
    }
|   _varchar2 '(' _intNumber ')'
    {
        size := $3
        d := &element.Varchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefVarchar2)
        $$ = d
    }
|   _varchar2 '(' _intNumber _byte ')'
    {
        size := $3
        d := &element.Varchar2{}
        d.Size = &size
        d.IsByteSize = true
        d.SetDataDef(element.DataDefVarchar2)
        $$ = d
    }
|   _varchar2 '(' _intNumber _char ')'
    {
        size := $3
        d := &element.Varchar2{}
        d.Size = &size
        d.IsCharSize = true
        d.SetDataDef(element.DataDefVarchar2)
        $$ = d
    }
|   _nchar
    {
        d := &element.NChar{}
        d.SetDataDef(element.DataDefNChar)
        $$ = d
    }
|   _nchar '(' _intNumber ')'
    {
        size := $3
        d := &element.NChar{Size: &size}
        d.SetDataDef(element.DataDefNChar)
        $$ = d
    }
|   _nvarchar2 '(' _intNumber ')'
    {
        size := $3
        d := &element.NVarchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefNVarChar2)
        $$ = d
    }

/*
NUMBER [ (p [, s]) ]:
Number having precision p and scale s. The precision p can range from 1 to 38. The scale s can range from -84 to 127.
Both precision and scale are in decimal digits. A NUMBER value requires from 1 to 22 bytes.

FLOAT [(p)]
A subtype of the NUMBER data type having precision p. A FLOAT value is represented internally as NUMBER.
The precision p can range from 1 to 126 binary digits. A FLOAT value requires from 1 to 22 bytes.
 */
NumberDataTypes:
    _number
    {
        d := &element.Number{}
        d.SetDataDef(element.DataDefNumber)
        $$ = d
    }
|   _number '(' NumberOrAsterisk ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefNumber)
        $$ = d
    }
|   _number '(' NumberOrAsterisk ',' _intNumber ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        scale := $5
        d := &element.Number{Precision: precision, Scale: &scale}
        d.SetDataDef(element.DataDefNumber)
        $$ = d
    }
|   _float
    {
        d := &element.Float{}
        d.SetDataDef(element.DataDefFloat)
        $$ = d
    }
|   _float '(' NumberOrAsterisk ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        d := &element.Float{Precision: precision}
        d.SetDataDef(element.DataDefFloat)
        $$ = d
    }
|   _binaryFloat
    {
        d := &element.BinaryFloat{}
        d.SetDataDef(element.DataDefBinaryFloat)
        $$ = d
    }
|   _binaryDouble
    {
        d := &element.BinaryDouble{}
        d.SetDataDef(element.DataDefBinaryDouble)
        $$ = d
    }

/*
RAW(size):
Raw binary data of length size bytes. You must specify size for a RAW value. Maximum size is:
- 32767 bytes if MAX_STRING_SIZE = EXTENDED
- 2000 bytes if MAX_STRING_SIZE = STANDARD
 */
LongAndRawDataTypes:
    _long
    {
        d := &element.Long{}
        d.SetDataDef(element.DataDefLong)
        $$ = d
    }
|   _long _raw
    {
        d := &element.LongRaw{}
        d.SetDataDef(element.DataDefLongRaw)
        $$ = d
    }
|   _raw '(' _intNumber ')'
    {
        size := $3
        d := &element.Raw{Size: &size}
        d.SetDataDef(element.DataDefRaw)
        $$ = d
    }

/*
TIMESTAMP [(fractional_seconds_precision)]:
Year, month, and day values of date, as well as hour, minute, and second values of time,
where fractional_seconds_precision is the number of digits in the fractional part of the SECOND datetime field.
Accepted values of fractional_seconds_precision are 0 to 9. The default is 6.

INTERVAL YEAR [(year_precision)] TO MONTH:
Stores a period of time in days, hours, minutes, and seconds, where
- day_precision is the maximum number of digits in the DAY datetime field.
  Accepted values are 0 to 9. The default is 2.

- fractional_seconds_precision is the number of digits in the fractional part of the SECOND field.
  Accepted values are 0 to 9. The default is 6.
 */
DatetimeDataTypes:
    _date
    {
        d := &element.Date{}
        d.SetDataDef(element.DataDefDate)
        $$ = d
    }
|   _timestamp
    {
        d := &element.Timestamp{}
        d.SetDataDef(element.DataDefTimestamp)
        $$ = d
    }
|   _timestamp '(' _intNumber ')'
    {
        precision := $3
        d := &element.Timestamp{FractionalSecondsPrecision: &precision}
        d.SetDataDef(element.DataDefTimestamp)
        $$ = d
    }
|   _timestamp '(' _intNumber ')' _with _time _zone
    {
        precision := $3
        d := &element.Timestamp{FractionalSecondsPrecision: &precision, WithTimeZone: true}
        d.SetDataDef(element.DataDefTimestamp)
        $$ = d
    }
|   _timestamp '(' _intNumber ')' _with _local _time _zone
    {
        precision := $3
        d := &element.Timestamp{FractionalSecondsPrecision: &precision, WithLocalTimeZone: true}
        d.SetDataDef(element.DataDefTimestamp)
        $$ = d
    }
|   _interval _year _to _mouth
    {
        d := &element.IntervalYear{}
        d.SetDataDef(element.DataDefIntervalYear)
        $$ = d
    }
|   _interval _year '(' _intNumber ')' _to _mouth
    {
        precision := $4
        d := &element.IntervalYear{Precision: &precision}
        d.SetDataDef(element.DataDefIntervalYear)
        $$ = d
    }
|   _interval _day _to _second
    {
        d := &element.IntervalDay{}
        d.SetDataDef(element.DataDefIntervalDay)
        $$ = d
    }
|   _interval _day '(' _intNumber ')' _to _second
    {
        precision := $4
        d := &element.IntervalDay{Precision: &precision}
        d.SetDataDef(element.DataDefIntervalDay)
        $$ = d
    }
|   _interval _day '(' _intNumber ')' _to _second '(' _intNumber ')'
    {
        precision := $4
        sPrecision := $9
        d := &element.IntervalDay{Precision: &precision, FractionalSecondsPrecision: &sPrecision}
        d.SetDataDef(element.DataDefIntervalDay)
        $$ = d
    }
|   _interval _day _to _second '(' _intNumber ')'
    {
        sPrecision := $6
        d := &element.IntervalDay{FractionalSecondsPrecision: &sPrecision}
        d.SetDataDef(element.DataDefIntervalDay)
        $$ = d
    }

LargeObjectDataTypes:
    _blob
    {
        d := &element.Blob{}
        d.SetDataDef(element.DataDefBlob)
        $$ = d
    }
|   _clob
    {
        d := &element.Clob{}
        d.SetDataDef(element.DataDefClob)
        $$ = d
    }
|   _nclob
    {
        d := &element.NClob{}
        d.SetDataDef(element.DataDefNClob)
        $$ = d
    }
|   _bfile
    {
        d := &element.BFile{}
        d.SetDataDef(element.DataDefBFile)
        $$ = d
    }

/*
UROWID [(size)]:
Base 64 string representing the logical address of a row of an index-organized table.
The optional size is the size of a column of type UROWID. The maximum size and default is 4000 bytes.
*/
RowIdDataTypes:
    _rowid
    {
        d := &element.RowId{}
        d.SetDataDef(element.DataDefRowId)
        $$ = d
    }
|    _urowid
    {
        d := &element.URowId{}
        d.SetDataDef(element.DataDefURowId)
        $$ = d
    }
|   _urowid '(' _intNumber ')'
    {
        size := $3
        d := &element.URowId{Size: &size}
        d.SetDataDef(element.DataDefURowId)
        $$ = d
    }

AnsiSupportDataTypes:
    _character '(' _intNumber ')'
    {
        d := &element.Char{}
        d.SetDataDef(element.DataDefCharacter)
        $$ = d
    }
|   _character _varying '(' _intNumber ')'
    {
        size := $4
        d := &element.Varchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefCharacterVarying)
        $$ = d
    }
|   _char _varying '(' _intNumber ')'
    {
        size := $4
        d := &element.Varchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefCharVarying)
        $$ = d
    }
|   _nchar _varying '(' _intNumber ')'
    {
        size := $4
        d := &element.NVarchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefNCharVarying)
        $$ = d
    }
|   _varchar '(' _intNumber ')'
    {
        size := $3
        d := &element.Varchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefVarchar)
        $$ = d
    }
|   _national _character '(' _intNumber ')'
    {
        size := $4
        d := &element.NChar{Size: &size}
        d.SetDataDef(element.DataDefNationalCharacter)
        $$ = d
    }
|   _national _character _varying '(' _intNumber ')'
    {
        size := $5
        d := &element.NVarchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefNationalCharacterVarying)
        $$ = d
    }
|   _national _char '(' _intNumber ')'
    {
        size := $4
        d := &element.NChar{Size: &size}
        d.SetDataDef(element.DataDefNationalChar)
        $$ = d
    }
|   _national _char _varying '(' _intNumber ')'
    {
        size := $5
        d := &element.NVarchar2{}
        d.Size = &size
        d.SetDataDef(element.DataDefNationalCharVarying)
        $$ = d
    }
|   _numeric
    {
        d := &element.Number{}
        d.SetDataDef(element.DataDefNumeric)
        $$ = d
    }
|   _numeric '(' NumberOrAsterisk ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefNumeric)
        $$ = d
    }
|   _numeric '(' NumberOrAsterisk '.' _intNumber ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        scale := $5
        d := &element.Number{Precision: precision, Scale: &scale}
        d.SetDataDef(element.DataDefNumeric)
        $$ = d
    }
|   _decimal
    {
        d := &element.Number{}
        d.SetDataDef(element.DataDefDecimal)
        $$ = d
    }
|   _decimal '(' NumberOrAsterisk ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefDecimal)
        $$ = d
    }
|   _decimal '(' NumberOrAsterisk '.' _intNumber ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        scale := $5
        d := &element.Number{Precision: precision, Scale: &scale}
        d.SetDataDef(element.DataDefDecimal)
        $$ = d
    }
|   _dec
    {
        d := &element.Number{}
        d.SetDataDef(element.DataDefDec)
        $$ = d
    }
|   _dec '(' NumberOrAsterisk ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefDec)
        $$ = d
    }
|   _dec '(' NumberOrAsterisk '.' _intNumber ')'
    {
        precision := $3.(*element.NumberOrAsterisk)
        scale := $5
        d := &element.Number{Precision: precision, Scale: &scale}
        d.SetDataDef(element.DataDefDec)
        $$ = d
    }
|   _interger
    {
        precision := &element.NumberOrAsterisk{Number: 38}
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefInteger)
        $$ = d
    }
|   _int
    {
        precision := &element.NumberOrAsterisk{Number: 38}
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefInt)
        $$ = d
    }
|   _smallInt
    {
        precision := &element.NumberOrAsterisk{Number: 38}
        d := &element.Number{Precision: precision}
        d.SetDataDef(element.DataDefSmallInt)
        $$ = d
    }
|   _double _precision
    {
        precision := &element.NumberOrAsterisk{Number: 126}
        d := &element.Float{Precision: precision}
        d.SetDataDef(element.DataDefDoublePrecision)
        $$ = d
    }
|   _real
    {
        precision := &element.NumberOrAsterisk{Number: 63}
        d := &element.Float{Precision: precision}
        d.SetDataDef(element.DataDefReal)
        $$ = d
    }

/* +++++++++++++++++++++++++++++++++++++++++++++ constraint ++++++++++++++++++++++++++++++++++++++++++++ */

// see https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/constraint.html#GUID-1055EA97-BA6F-4764-A15F-1024FD5B6DFE
//Constraint:
//    InlineConstraint
//|   OutOfLineConstraint
//|   InlineRefConstraint
//|   OutOfLineRefConstraint

ConstraintNameOrEmpty:
    {
        // empty
    }
|   _constraint Identifier

InlineConstraint:
    ConstraintNameOrEmpty InlineConstraintProp ConstraintStateOrEmpty

InlineConstraintProp:
    _null
|   _not _null
|   _unique
|   _primary _key
|   ReferencesClause
//|   ConstraintCheckCondition // todo

ReferencesClause:
    _references TableName ColumnNameListOrEmpty ReferencesOnDelete

ColumnNameListOrEmpty:
    {
        // empty
    }
|   '(' ColumnNameList ')'

ReferencesOnDelete:
    {
        // empty
    }
|   _on _delete _cascade
|   _on _delete _set _null

ConstraintStateOrEmpty:
    {
        // empty
    }
|   ConstraintState

ConstraintState: // todo: support using_index_clause, enable/disable, validate, exceptions_clause
    ConstraintStateDeferrable ConstraintStateRely
|   ConstraintStateDeferrable ConstraintStateDeferredOrImmediate ConstraintStateRely
|   ConstraintStateDeferredOrImmediate ConstraintStateRely
|   ConstraintStateDeferredOrImmediate ConstraintStateDeferrable ConstraintStateRely

ConstraintStateDeferrable:
    _deferrable
|   _not _deferrable

ConstraintStateDeferredOrImmediate:
    _initially _deferred
|   _initially _immediate

ConstraintStateRely:
    {
        // empty
    }
|   _rely
|   _norely

InlineRefConstraint:
    _scope _is TableName
|   _with _rowid
|   ConstraintNameOrEmpty ReferencesClause ConstraintStateOrEmpty

/* +++++++++++++++++++++++++++++++++++++++++ memoptimize +++++++++++++++++++++++++++++++++++++++++ */

MemoptimizeForAlterTable:
    MemoptimizeReadForAlterTable MemoptimizeWriteForAlterTable

MemoptimizeReadForAlterTable:
    MemoptimizeRead
|   _no _memoptimize _for _read

MemoptimizeWriteForAlterTable:
    MemoptimizeWrite
|   _no _memoptimize _for _write

Memoptimize:
    MemoptimizeRead MemoptimizeWrite

MemoptimizeRead:
    {
        // empty
    }
|   _memoptimize _for _read

MemoptimizeWrite:
    {
        // empty
    }
|   _memoptimize _for _write

/* +++++++++++++++++++++++++++++++++++++++++++++ expr ++++++++++++++++++++++++++++++++++++++++++++ */

// see https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/Expressions.html#GUID-E7A5363C-AEE9-4809-99C1-1A9C6E3AE017

// TODO: support expression
Expr:
    _intNumber
|   _doubleQuoteStr

%%