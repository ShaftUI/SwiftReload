import SwiftSyntax

/// Represents a declaration in the source code.
public class Declaration {
    init(
        _ declaration: DeclSyntaxProtocol,
        name: String,
        scope: [String] = [],
        signature: String = "",
        code: String = ""
    ) {
        self.syntax = declaration
        self.name = name
        self.scope = scope
        self.signature = signature
        self.code = code
    }

    /// The name of the declaration.
    let name: String

    /// The signature of the declaration. Only available for functions.
    let signature: String

    /// The code of the declaration. Only available for functions.
    let code: String

    /// The scope of the declaration. Top level declarations have an empty
    /// scope.
    let scope: [String]

    /// The syntax node of the declaration.
    let syntax: DeclSyntaxProtocol
}

extension Declaration: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "declaration": type(of: syntax),
                "name": name,
                "scope": scope,
                "signature": signature,
                "code": code,
            ],
            displayStyle: .class
        )
    }
}

/// Recursively extract all declarations from a source file.
public func toDeclarations(file: SourceFileSyntax) -> [Declaration] {
    let builder = DeclarationNodeBuilder()
    return builder.build(file: file)
}

private class DeclarationNodeBuilder: SyntaxVisitor {
    init() {
        super.init(viewMode: .fixedUp)
    }

    var result = [Declaration]()
    var stack = [Declaration]()

    private var currentScope: [String] {
        stack.map(\.name)
    }

    private func push(_ node: Declaration) {
        result.append(node)
        stack.append(node)
    }

    private func pop() {
        stack.removeLast()
    }

    override func visit(_ decl: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = decl.name.text
        let signature = decl.signature.description
        let code = decl.body!.formatted().description
        let node = Declaration(
            decl,
            name: name,
            scope: currentScope,
            signature: signature,
            code: code
        )
        push(node)
        return .skipChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        pop()
    }

    override func visit(_ decl: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = decl.name.text
        let node = Declaration(decl, name: name, scope: currentScope)
        push(node)
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        pop()
    }

    override func visit(_ decl: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    func build(file: SourceFileSyntax) -> [Declaration] {
        result = []
        stack = []
        walk(file)
        return result
    }
}

/// Represents the different types of changes that can occur between two sets of
/// declarations.
public enum SyntaxDiff {
    /// A new declaration has been added.
    case added(Declaration)

    /// An existing declaration has been removed.
    case removed(Declaration)

    /// An existing declaration has been changed.
    case changed(Declaration, Declaration)
}

/// Perform a diff between two sets of declarations.
public func performDiff(_ oldDeclarations: [Declaration], _ newDeclarations: [Declaration])
    -> [SyntaxDiff]
{
    var result = [SyntaxDiff]()

    for old in oldDeclarations {
        if let new = newDeclarations.first(where: {
            $0.scope == old.scope && $0.name == old.name && $0.signature == old.signature
        }) {
            if old.code != new.code {
                result.append(.changed(old, new))
            }
        } else {
            result.append(.removed(old))
        }
    }

    for new in newDeclarations {
        if !oldDeclarations.contains(where: { $0.name == new.name }) {
            result.append(.added(new))
        }
    }

    return result
}
