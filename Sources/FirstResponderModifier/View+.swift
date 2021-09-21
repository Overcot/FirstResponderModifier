import Combine
import SwiftUI

// https://github.com/SwiftUIX/SwiftUIX
extension View {
    @_disfavoredOverload
    @ViewBuilder
    func onChange<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        #if os(iOS) || os(watchOS) || os(tvOS) || targetEnvironment(macCatalyst)
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            onChange(of: value, perform: action)
        } else {
            _backport_onChange(of: value, perform: action)
        }
        #else
        _backport_onChange(of: value, perform: action)
        #endif
    }

    @ViewBuilder
    private func _backport_onChange<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        OnChangeOfValue(base: self, value: value, action: action)
    }
}

// MARK: - Auxiliary Implementation -

// A modified implementation based on https://stackoverflow.com/questions/58363563/swiftui-get-notified-when-binding-value-changes
private struct OnChangeOfValue<Base: View, Value: Equatable>: View {
    class ValueBox {
        private var savedValue: Value?

        func update(value: Value) -> Bool {
            guard value != savedValue else {
                return false
            }

            savedValue = value

            return true
        }
    }

    let base: Base
    let value: Value
    let action: (Value) -> Void

    @State private var valueBox = ValueBox()
    @State private var oldValue: Value?

    var body: some View {
        if valueBox.update(value: value) {
            DispatchQueue.main.async {
                action(value)

                oldValue = value
            }
        }

        return base
    }
}
