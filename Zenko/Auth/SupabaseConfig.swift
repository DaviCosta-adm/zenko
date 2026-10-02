import Foundation

/// Dados do projeto Supabase do Zenko (Project Settings → API).
/// A chave pública (anon/publishable) pode ficar no app: quem protege os dados é o RLS.
/// Nunca coloque aqui a `service_role` key.
enum SupabaseConfig {
    static let url = ""
    static let chavePublica = ""
}
