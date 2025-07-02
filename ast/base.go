package ast

import (
	"github.com/codeindex2937/oracle-sql-parser/ast/element"
)

type TableName struct {
	Schema *element.Identifier
	Table  *element.Identifier
}

type IndexName struct {
	Schema *element.Identifier
	Index  *element.Identifier
}

type SequenceName struct {
	Schema   *element.Identifier
	Sequence *element.Identifier
}

type Collation struct {
	Name *element.Identifier
}

type ColumnProp int

const (
	ColumnPropEmpty ColumnProp = iota
	ColumnPropSort             // for add column
	ColumnPropInvisible
	ColumnPropVisible
	ColumnPropSubstitutable         // for modify column
	ColumnPropNotSubstitutable      // for modify column
	ColumnPropSubstitutableForce    // for modify column
	ColumnPropNotSubstitutableForce // for modify column
)

type ColumnDefault struct {
	OnNull bool
	Value  interface{}
}

type ConstraintType int

const (
	ConstraintTypeDefault ConstraintType = iota
	ConstraintTypeNull
	ConstraintTypeNotNull
	ConstraintTypeUnique
	ConstraintTypePK
	ConstraintTypeReferences
)

//type ConstraintState int

//const (
//	ConstraintStateDeferrable ConstraintState = iota
//	ConstraintStateNotDeferrable
//	ConstraintStateInitiallyDeferred
//	ConstraintStateInitiallyImmediate
//	ConstraintStateRely
//	ConstraintStateNorely
//)

type DropColumnType int

const (
	DropColumnTypeDrop DropColumnType = iota
	DropColumnTypeSetUnused
	DropColumnTypeDropUnusedColumns
	DropColumnTypeDropColumnsContinue
)

type DropColumnProp int

const (
	DropColumnPropEmpty DropColumnProp = iota
	DropColumnPropCascade
	DropColumnPropInvalidate
	DropColumnPropOnline
)

type ReferenceAction int

const (
	RefOptNoAction ReferenceAction = iota
	RefOptCascade
	RefOptRestrict
	RefOptSetNull
	RefOptSetDefault
)

type SortDirection int

const (
	Ascend SortDirection = iota
	Descend
)
