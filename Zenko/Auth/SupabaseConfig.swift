import Foundation

/// Dados do projeto Supabase do Zenko (Project Settings → API).
/// A chave pública (anon/publishable) pode ficar no app: quem protege os dados é o RLS.
/// Nunca coloque aqui a `service_role` key.
enum SupabaseConfig {
    static let url = "https://ouhswumipggqoafnofch.supabase.co"
    static let chavePublica = "sb_publishable_IW8gZUidPLk5EqfB5KYkhA_4yXBFe5g"
}
