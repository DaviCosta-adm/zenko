import Foundation
import Security

/// A sessão (tokens) fica no Keychain, nunca em UserDefaults.
enum KeychainSessao {
    private static let servico = "app.zenko.Zenko.sessao"
    private static let conta = "supabase"

    private static var consultaBase: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servico,
            kSecAttrAccount as String: conta,
        ]
    }

    static func salvar(_ sessao: SessaoSupabase) {
        guard let dados = try? JSONEncoder().encode(sessao) else { return }
        SecItemDelete(consultaBase as CFDictionary)
        var item = consultaBase
        item[kSecValueData as String] = dados
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    static func carregar() -> SessaoSupabase? {
        var consulta = consultaBase
        consulta[kSecReturnData as String] = true
        consulta[kSecMatchLimit as String] = kSecMatchLimitOne

        var resultado: AnyObject?
        guard SecItemCopyMatching(consulta as CFDictionary, &resultado) == errSecSuccess,
              let dados = resultado as? Data else { return nil }
        return try? JSONDecoder().decode(SessaoSupabase.self, from: dados)
    }

    static func apagar() {
        SecItemDelete(consultaBase as CFDictionary)
    }
}
