/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A protocol and conforming extensions for subscripting with an expression.
*/

import SQLite

protocol ExpressionSubscriptable {
    subscript<T: Value>(column: Expression<T>) -> T {
        get
    }
    subscript<T: Value>(column: Expression<T?>) -> T? {
        get
    }
}

extension Row: ExpressionSubscriptable {}

private extension String {
    func quote(_ mark: Character = "\"") -> String {
        let escaped = reduce(into: "") { string, character in
            string += character == mark ? "\(mark)\(mark)" : "\(character)"
        }
        return "\(mark)\(escaped)\(mark)"
    }
}

struct RowWrapper: ExpressionSubscriptable {

    let columnNames: [String]

    fileprivate let values: [Binding?]

    init(_ columnNames: [String], _ values: [Binding?]) {
        self.columnNames = columnNames.map({ $0.quote() })
        self.values = values
    }

    /// Returns a row’s value for the given column.
    ///
    /// - Parameter column: An expression representing a column selected in a Query.
    ///
    /// - Returns: The value for the given column.
    public func get<V: Value>(_ column: Expression<V>) throws -> V {
        if let value = try get(Expression<V?>(column)) {
            return value
        } else {
            throw QueryError.unexpectedNullValue(name: column.template)
        }
    }

    public func get<V: Value>(_ column: Expression<V?>) throws -> V? {
        func valueAtIndex(_ idx: Int) -> V? {
            guard let value = values[idx] as? V.Datatype else { return nil }
            return V.fromDatatypeValue(value) as? V
        }

        guard let idx = columnNames.firstIndex(of: column.template) else {
            throw QueryError.noSuchColumn(name: column.template, columns: columnNames.sorted())
        }

        return valueAtIndex(idx)
    }

    public subscript<T: Value>(column: Expression<T>) -> T {
        return try! get(column)
    }

    public subscript<T: Value>(column: Expression<T?>) -> T? {
        return try! get(column)
    }
}
