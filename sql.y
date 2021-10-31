%{
package parser

import (
	"strings"

	"github.com/sjjian/oracle-sql-parser/ast"
	"github.com/sjjian/oracle-sql-parser/ast/element"
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
    _cluster
    _organization
    _creation
    _segment
    _tablespace
    _initrans
    _maxtrans
    _pctfree
    _pctused
    _storage
    _buffer_pool
    _cell_flash_cache
    _flash_cache
    _freelist
    _freelists
    _initial
    _keep
    _maxextents
    _maxsize
    _minextents
    _next
    _optimal
    _pctincrease
    _recycle
    _unlimited
    _groups
    _E
    _G
    _K
    _M
    _P
    _T
    _filesystem_like_logging
    _logging
    _nologging
    _advanced
    _basic
    _compress
    _nocompress
    _row
    _store
    _archive
    _query
    _level
    _locking
    _inmemory
    _auto
    _capacity
    _dml
    _high
    _low
    _memcompress
    _critical
    _medium
    _priority
    _distribute
    _partition
    _range
    _subpartition
    _service
    _duplicate
    _spatial
    _delete_all
    _disable
    _disable_all
    _enable
    _enable_all
    _ilm
    _policy
    _external
    _heap
    _index
    _attributes
    _reject
    _foreign
    _novalidate
    _validate
    _exceptions
    _into
    _bitmap
    _multivalue
    _nosort
    _peverse
    _full
    _indexing
    _partial
    _noparallel
    _parallel
    _asc
    _desc
    _usable
    _unusable
    _invalidation

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
    InlineConstraintType

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
    CreateIndexStmt

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
    AlterTableClauses
    ColumnClauses
    ConstraintClauses
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
    OutOfLineConstraint
    ConstraintNameOrEmpty
    ColumnDefConstraint
    InlineConstraintList
    InlineConstraint
    DropConstraintClauses
    DropConstraintClause

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
|   CreateIndexStmt

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

ClusterName:
    Identifier
|   Identifier '.' Identifier

/* +++++++++++++++++++++++++++++++++++++++++++++ alter table ++++++++++++++++++++++++++++++++++++++++++++ */

// see: https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/ALTER-TABLE.html#GUID-552E7373-BF93-477D-9DA3-B2C9386F2877
AlterTableStmt:
    _alter _table TableName MemoptimizeForAlterTable AlterTableClauses
    {
        $$ = &ast.AlterTableStmt{
            TableName:      	$3.(*ast.TableName),
            AlterTableClauses:  $5.([]ast.AlterTableClause),
        }
    }

AlterTableClauses:
    ColumnClauses
    {
        $$ = $1
    }
|   ConstraintClauses
    {
        $$ = $1
    }

ColumnClauses:
    ChangeColumnClauseList
    {
        $$ = $1
    }
|   RenameColumnClause
    {
        $$ = []ast.AlterTableClause{$1.(ast.AlterTableClause)}
    }

ChangeColumnClauseList:
    ChangeColumnClause
    {
        $$ = []ast.AlterTableClause{$1.(ast.AlterTableClause)}
    }
|   ChangeColumnClauseList ChangeColumnClause
    {
        $$ = append($1.([]ast.AlterTableClause), $2.(ast.AlterTableClause))
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

        var constraints []*ast.InlineConstraint
        if $8 != nil {
            constraints = $8.([]*ast.InlineConstraint)
        }

        $$ = &ast.ColumnDef{
            ColumnName:         $1.(*element.Identifier),
            Datatype:           $2.(element.Datatype),
            Collation:          collation,
            Props:              props,
            Constraints: 	constraints,
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
        $$ = nil
    }
|   InlineRefConstraint
    {
        $$ = nil
    }
|   InlineConstraintList
    {
        $$ = $1
    }

InlineConstraintList:
    InlineConstraint
    {
        $$ = []*ast.InlineConstraint{$1.(*ast.InlineConstraint)}
    }
|   InlineConstraintList InlineConstraint
    {
        $$ = append($1.([]*ast.InlineConstraint), $2.(*ast.InlineConstraint))
    }

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

/* +++++++++++++++++++++++++++++++++++++ alter table constraint  +++++++++++++++++++++++++++++++++++++ */

ConstraintClauses:
    _add OutOfLineConstraints
    {
    	$$ = []ast.AlterTableClause{&ast.AddConstraintClause{}}
    }
//|   _add OutOfLineRefConstraint // TODO
|   _modify _constraint Identifier ConstraintState CascadeOrEmpty
    {
    	$$ = []ast.AlterTableClause{&ast.ModifyConstraintClause{}}
    }
|   _modify _primary _key ConstraintState CascadeOrEmpty
    {
    	$$ = []ast.AlterTableClause{&ast.ModifyConstraintClause{}}
    }
|   _modify _unique '(' ColumnNameList ')' ConstraintState CascadeOrEmpty
    {
    	$$ = []ast.AlterTableClause{&ast.ModifyConstraintClause{}}
    }
|   _rename _constraint Identifier _to Identifier
    {
    	$$ = []ast.AlterTableClause{&ast.RenameConstraintClause{}}
    }
|   DropConstraintClauses
    {
    	$$ = $1
    }

OutOfLineConstraints:
    OutOfLineConstraint
|   OutOfLineConstraints OutOfLineConstraint

DropConstraintClauses:
    DropConstraintClause
    {
        $$ = []ast.AlterTableClause{$1.(ast.AlterTableClause)}
    }
|   DropConstraintClauses DropConstraintClause
    {
        $$ = append($1.([]ast.AlterTableClause), $2.(ast.AlterTableClause))
    }

DropConstraintClause:
    _drop _primary _key CascadeOrEmpty DropConstraintProps
    {
    	$$ = &ast.DropConstraintClause{}
    }
|   _drop _unique '(' ColumnNameList ')' CascadeOrEmpty DropConstraintProps
    {
    	$$ = &ast.DropConstraintClause{}
    }
|   _drop _constraint Identifier CascadeOrEmpty DropConstraintProps
    {
    	$$ = &ast.DropConstraintClause{}
    }

CascadeOrEmpty:
    {
        // empty
    }
|   _cascade

DropConstraintProps:
    KeepIndexOrEmpty OnlineOrEmpty

KeepIndexOrEmpty:
    {
        // empty
    }
|   _keep _index
//|   _drop _index // TODO : conflict DropConstraintClause

OnlineOrEmpty:
    {
        // empty
    }
|   _online

/* +++++++++++++++++++++++++++++++++++++++++++ create table ++++++++++++++++++++++++++++++++++++++++++ */

// see: https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6
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
            rd.TableStructs = $1.([]ast.TableStructDef)
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

PhysicalProps:
    {
        // empty
    }
|   DeferredSegmentCreation SegmentAttrsClause TableCompressionOrEmpty InmemoryTableClause IlmClause
|   DeferredSegmentCreation _organization OrgClause
|   DeferredSegmentCreation ExternalPartitionClause
|   _cluster Identifier  '(' ColumnNameList ')'

DeferredSegmentCreation:
    {
        // empty
    }
|   _segment _creation _immediate
|   _segment _creation _deferred

SegmentAttrsClauseOrEmpty:
    {
        // empty
    }
|   SegmentAttrsClause

SegmentAttrsClause:
    SegmentAttrClause
|   SegmentAttrsClause SegmentAttrClause

SegmentAttrClause:
    PhysicalAttrsClause
|   _tablespace Identifier
|   _tablespace _set Identifier
|   LoggingClause
|   TableCompression // TODO: this is not include in oracle 21 syntax docs

PhysicalAttrsClause:
    PhysicalAttrClause
|   PhysicalAttrsClause PhysicalAttrClause

PhysicalAttrClause:
    _pctfree _intNumber
|   _pctused _intNumber
|   _initrans _intNumber
|   _maxtrans _intNumber // has been deprecated,
|   StorageClause

LoggingClause:
    _logging
|   _nologging
|   _filesystem_like_logging

TableCompressionOrEmpty:
    {
        // empty
    }
|   TableCompression

TableCompression:
    _compress
|   _row _store _compress
|   _row _store _compress _basic
|   _row _store _compress _advanced
|   _column _store _compress ColumnCompressProp ColumnCompressLock
|   _nocompress

ColumnCompressProp:
    {
        // empty
    }
|   _for _query
|   _for _query _low
|   _for _query _high
|   _for _archive
|   _for _archive _low
|   _for _archive _high

ColumnCompressLock:
    {
        // empty
    }
|   _row _level _locking
|   _no _row _level _locking

InmemoryTableClause:
    {
        // empty
    }
|   _inmemory InmemoryAttrs InmemoryColumnClausesOrEmpty
|   _no _inmemory InmemoryColumnClausesOrEmpty
|   InmemoryColumnClausesOrEmpty

InmemoryAttrs:
    InmemoryMemCompress InmemoryProp InmemoryDistribute InmemoryDuplicate InmemorySpatial

InmemoryMemCompress:
    {
        // empty
    }
|   _memcompress _for _dml
|   _memcompress _for _query
|   _memcompress _for _query _low
|   _memcompress _for _query _high
|   _memcompress _for _capacity
|   _memcompress _for _capacity _low
|   _memcompress _for _capacity _high
|   _no _memcompress
|   _memcompress _auto

InmemoryProp:
    {
        // empty
    }
|   _priority _none
|   _priority _low
|   _priority _medium
|   _priority _high
|   _priority _critical

InmemoryDistribute:
    {
        // empty
    }
|   _distribute InmemoryDistributeBy InmemoryDistributeFor

InmemoryDistributeBy:
    {
        // empty
    }
|   _auto
|   _by _rowid _range
|   _by _partition
|   _by _subpartition

InmemoryDistributeFor:
    {
        // empty
    }
|   _for _service _default
|   _for _service _all
|   _for _service Identifier
|   _for _service _none

InmemoryDuplicate:
    {
        // empty
    }
|   _duplicate
|   _duplicate _all
|   _no _duplicate

InmemorySpatial:
    {
        // empty
    }
|   _spatial ColumnName

InmemoryColumnClausesOrEmpty:
    {
        // empty
    }
|   InmemoryColumnClauses

InmemoryColumnClauses:
    InmemoryColumnClause
|   InmemoryColumnClauses InmemoryColumnClause

InmemoryColumnClause:
    _inmemory '(' ColumnNameList ')'
|   _inmemory InmemoryMemCompress '(' ColumnNameList ')'
|   _no _inmemory '(' ColumnNameList ')'

IlmClause:
    {
        // empty
    }
|   _ilm _add _policy IlmPolicyClause
|   _ilm _delete _policy IlmPolicyClause
|   _ilm _enable _policy IlmPolicyClause
|   _ilm _disable _policy IlmPolicyClause
|   _ilm _delete_all
|   _ilm _enable_all
|   _ilm _disable_all

IlmPolicyClause:
    IlmCompressionPolicy
|   IlmTieringPolicy
|   IlmInmemoryPolicy

IlmCompressionPolicy:

IlmTieringPolicy:

IlmInmemoryPolicy:

OrgClause:
    _heap SegmentAttrsClauseOrEmpty HeapOrgTableClause
|   _index SegmentAttrsClauseOrEmpty IndexOrgTableClause
|   _external ExternalTableClause

HeapOrgTableClause:
    TableCompressionOrEmpty InmemoryTableClause IlmClause

IndexOrgTableClause:

ExternalTableClause:

ExternalPartitionClause:
    _external _partition _attributes ExternalTableClause
|   _external _partition _attributes ExternalTableClause _reject _limit

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
        $$ = []ast.TableStructDef{$1.(ast.TableStructDef)}
    }
|   RelTableProps ',' RelTableProp
    {
        $$ = append($1.([]ast.TableStructDef), $3.(ast.TableStructDef))
    }

RelTableProp:
    ColumnDef
    {
        $$ = $1
    }
|   OutOfLineConstraint
    {
        $$ = $1
    }

/* ++++++++++++++++++++++++++++++++++++++++++++ create index +++++++++++++++++++++++++++++++++++++++++++ */

// see: https://docs.oracle.com/en/database/oracle/oracle-database/21/sqlrf/CREATE-INDEX.html#GUID-1F89BBC0-825F-4215-AF71-7588E31D8BFE
CreateIndexStmt:
    _create IndexType _index IndexName IndexIlmClause _on IndexClause CreateIndexUsable CreateIndexInvalidation
    {
        $$ = &ast.CreateIndexStmt{}
    }

IndexType:
    {
        // empty
    }
|   _unique
|   _bitmap
|   _multivalue

IndexName:
    Identifier
|   Identifier '.' Identifier

IndexIlmClause:

IndexClause:
    ClusterIndexClause
|   TableIndexClause
|   BitmapJoinIndexClause

ClusterIndexClause:
    _cluster ClusterName IndexAttrs

IndexAttrs:
    IndexAttr
|   IndexAttrs IndexAttr

IndexAttr:
    PhysicalAttrsClause
|   LoggingClause
|   _online
|   _tablespace Identifier
|   _tablespace _default
|   IndexCompression
|   _sort
|   _nosort
|   _peverse
|   _visible
|   _invisible
|   PartialIndexClause
|   ParallelClause

IndexCompression:
    _compress
|   _compress _intNumber
|   _compress _advanced
|   _compress _advanced _low
|   _compress _advanced _high
|   _nocompress

PartialIndexClause:
    _indexing _partial
|   _indexing _full

ParallelClause:
    _parallel
|   _parallel _intNumber
|   _noparallel

TableIndexClause:
    TableName TableAlias '(' IndexExprs ')' IndexProps

TableAlias:
    {
        // empty
    }
|   Identifier

IndexExprs:
    IndexExpr
|   IndexExprs ',' IndexExpr

IndexExpr:
    ColumnName ColumnSortClause
//|   ColumnExpr ColumnSortClause // TODO

ColumnSortClause:
    {
        // empty
    }
|   _asc
|   _desc

IndexProps: // TODO

BitmapJoinIndexClause: // TODO

CreateIndexUsable:
    {
        // empty
    }
|   _usable
|   _unusable

CreateIndexInvalidation:
    {
        // empty
    }
|   _deferred _invalidation
|   _immediate _invalidation

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
        $$ = nil
    }
|   _constraint Identifier
    {
        $$ = $2
    }

InlineConstraint:
    ConstraintNameOrEmpty InlineConstraintType ConstraintStateOrEmpty
    {
        constraint := &ast.InlineConstraint{}
        if $1 != nil {
            constraint.Name = $1.(*element.Identifier)
        }
	constraint.Type = ast.ConstraintType($2)
	$$ = constraint
    }
|   ConstraintNameOrEmpty ReferencesClause ConstraintStateOrEmpty
    {
        constraint := &ast.InlineConstraint{}
        if $1 != nil {
            constraint.Name = $1.(*element.Identifier)
        }
	constraint.Type = ast.ConstraintTypeReferences
	$$ = constraint
    }
//|   ConstraintCheckCondition // todo

InlineConstraintType:
    _null
    {
        $$ = int(ast.ConstraintTypeNull)
    }
|   _not _null
    {
        $$ = int(ast.ConstraintTypeNotNull)
    }
|   _unique
    {
        $$ = int(ast.ConstraintTypeUnique)
    }
|   _primary _key
    {
        $$ = int(ast.ConstraintTypePK)
    }

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
|   ConstraintStateList

ConstraintStateList:
    ConstraintState
|   ConstraintStateList ConstraintState

// ref: https://docs.oracle.com/cd/E11882_01/server.112/e41084/clauses002.htm#CJAFFBAA; TODO: is it diff from 12.1 docs?
ConstraintState:
    _deferrable
|   _not _deferrable
|   _initially _deferred
|   _initially _immediate
|   _rely
|   _norely
|   UsingIndexClause
|   _enable
|   _disable
|   _validate
|   _novalidate
|   ExceptionsClause

UsingIndexClause:
    _using _index IndexName
|   _using _index '(' CreateIndexStmt ')'
|   _using _index IndexProps

ExceptionsClause:
    _exceptions _into TableName

//ConstraintState: // todo: support using_index_clause, enable/disable, validate, exceptions_clause
//    ConstraintStateDeferrable ConstraintStateRely
//|   ConstraintStateDeferrable ConstraintStateDeferredOrImmediate ConstraintStateRely
//|   ConstraintStateDeferredOrImmediate ConstraintStateRely
//|   ConstraintStateDeferredOrImmediate ConstraintStateDeferrable ConstraintStateRely
//
//ConstraintStateDeferrable:
//    _deferrable
//|   _not _deferrable
//
//ConstraintStateDeferredOrImmediate:
//    _initially _deferred
//|   _initially _immediate
//
//ConstraintStateRely:
//    {
//        // empty
//    }
//|   _rely
//|   _norely

InlineRefConstraint:
    _scope _is TableName
|   _with _rowid
|   ConstraintNameOrEmpty ReferencesClause ConstraintStateOrEmpty

OutOfLineConstraint:
    ConstraintNameOrEmpty _unique '(' ColumnNameList ')' ConstraintStateOrEmpty
    {
        constraint := &ast.OutOfLineConstraint{}
        if $1 != nil {
            constraint.Name = $1.(*element.Identifier)
        }
	constraint.Type = ast.ConstraintTypeUnique
	constraint.Columns = $4.([]*element.Identifier)
	$$ = constraint
    }
|    ConstraintNameOrEmpty _primary _key '(' ColumnNameList ')' ConstraintStateOrEmpty
    {
        constraint := &ast.OutOfLineConstraint{}
        if $1 != nil {
            constraint.Name = $1.(*element.Identifier)
        }
	constraint.Type = ast.ConstraintTypePK
	constraint.Columns = $5.([]*element.Identifier)
	$$ = constraint
    }
|    ConstraintNameOrEmpty _foreign _key '(' ColumnNameList ')' ReferencesClause ConstraintStateOrEmpty
    {
        constraint := &ast.OutOfLineConstraint{}
        if $1 != nil {
            constraint.Name = $1.(*element.Identifier)
        }
	constraint.Type = ast.ConstraintTypeReferences
	constraint.Columns = $5.([]*element.Identifier)
	$$ = constraint
    }
//|   ConstraintCheckCondition // todo

//OutOfLineRefConstraint:
//    _scope _for '(' RefType ')' _is TableName
//|   _ref '(' RefType ')' _with _rowid
//|   ConstraintNameOrEmpty _foreign _key '(' RefTypeList ')' ReferencesClause ConstraintStateOrEmpty

/* +++++++++++++++++++++++++++++++++++++++++++++ storage ++++++++++++++++++++++++++++++++++++++++++++ */

StorageClause:
    _storage '(' StorageProps ')'

StorageProps:
    StorageProp
|   StorageProps StorageProp

StorageProp:
    _initial SizeClause
|   _next SizeClause
|   _minextents _intNumber
|   _maxextents _intNumber
|   _maxextents _unlimited
|   _maxsize _unlimited
|   _maxsize SizeClause
|   _pctincrease _intNumber
|   _freelists _intNumber
|   _freelist _groups _intNumber
|   _optimal
|   _optimal SizeClause
|   _optimal _null
|   _buffer_pool _keep
|   _buffer_pool _recycle
|   _buffer_pool _default
|   _flash_cache _keep
|   _flash_cache _none
|   _flash_cache _default
|   _cell_flash_cache _keep
|   _cell_flash_cache _none
|   _cell_flash_cache _default
|   _encrypt

SizeClause:
    _intNumber SizeUnit

SizeUnit:
    {
        // empty
    }
|   _K
|   _M
|   _G
|   _T
|   _P
|   _E

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