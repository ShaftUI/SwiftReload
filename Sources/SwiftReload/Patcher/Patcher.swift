import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

class Pacher {
    public init(patchID: Int = 0) {
        self.patchID = patchID
    }

    /// The ID of the patch. Used to generate unique patch function names.
    public let patchID: Int

    /// Generate a patch file that contains the diff between the old and new syntax.
    public func patch(oldSyntax: SourceFileSyntax, newSyntax: SourceFileSyntax, moduleName: String)
        -> SourceFileSyntax
    {
        var result = SourceFileSyntax {}
        patchImport(oldSyntax, moduleName: moduleName, result: &result)

        let oldDeclarations = toDeclarations(file: oldSyntax)
        let newDeclarations = toDeclarations(file: newSyntax)
        let diffs = performDiff(oldDeclarations, newDeclarations)
        patchCode(diffs, result: &result)

        return result
    }

    /// Add nessessary import for the patch module.
    private func patchImport(
        _ oldSyntax: SourceFileSyntax,
        moduleName: String,
        result: inout SourceFileSyntax
    ) {
        let importDecl = ImportDeclSyntax(
            path: .init(
                [.init(name: .init(stringLiteral: moduleName))]
            )
        )
        result.statements.append(.init(item: .init(importDecl)))

        for stmt in oldSyntax.statements {
            if let importDecl = ImportDeclSyntax(stmt.item) {
                result.statements.append(.init(item: .init(importDecl)))
            }
        }
    }

    /// Generate code for diffed declarations.
    private func patchCode(_ diffs: [SyntaxDiff], result: inout SourceFileSyntax) {
        for diff in diffs {
            switch diff {
            case .added(let decl):
                result.statements.append(.init(item: .init(decl.syntax)))
            case .changed(_, let newDecl):
                var patched = patchFunction(newDecl.syntax as! FunctionDeclSyntax)
                if !newDecl.scope.isEmpty {
                    var extensionScope = makeExtensionScope(newDecl.scope)
                    extensionScope.memberBlock.members.append(.init(decl: patched))
                    patched = extensionScope
                }
                result.statements.append(.init(item: .init(patched)))
            case .removed(_):
                break
            }
        }
    }

    /// Add `_dynamicReplacement` attribute to the function.
    private func patchFunction(_ node: FunctionDeclSyntax) -> DeclSyntaxProtocol {
        var result = node
        let dynamicReplacement = AttributeSyntax(
            attributeName: "_dynamicReplacement" as TypeSyntax,
            leftParen: .leftParenToken(),
            arguments: .dynamicReplacementArguments(
                .init(declName: DeclReferenceExprSyntax(baseName: node.name))
            ),
            rightParen: .rightParenToken()
        )
        result.attributes.append(.attribute(dynamicReplacement))
        result.name = getPatchName(node.name.text)
        return result
    }

    private func makeExtensionScope(_ scope: [String]) -> ExtensionDeclSyntax {
        return try! ExtensionDeclSyntax("extension \(raw: scope.joined(separator: ".")) {}")
    }

    private func getPatchName(_ originalName: String) -> TokenSyntax {
        return "\(raw: originalName)_patch_\(raw: patchID)"
    }
}
