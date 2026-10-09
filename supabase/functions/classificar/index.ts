import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CATEGORIAS = ["financeiro", "trabalho", "pessoal", "outro"] as const;
type Categoria = (typeof CATEGORIAS)[number];

const cabecalhos = {
  "Content-Type": "application/json",
  "Connection": "keep-alive",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cabecalhos });
  }
  if (req.method !== "POST") {
    return json({ erro: "use POST" }, 405);
  }

  const chave = Deno.env.get("ANTHROPIC_API_KEY");
  if (!chave) {
    return json({ erro: "IA ainda não configurada" }, 503);
  }

  let corpo: { titulo?: unknown; conteudo?: unknown; origem?: unknown };
  try {
    corpo = await req.json();
  } catch {
    return json({ erro: "JSON inválido" }, 400);
  }

  const titulo = textoCurto(corpo.titulo, 200);
  const conteudo = textoCurto(corpo.conteudo, 2000);
  const origem = textoCurto(corpo.origem, 40);
  if (!titulo && !conteudo) {
    return json({ erro: "informe titulo ou conteudo" }, 400);
  }

  const prompt = `Classifique o item. Responda APENAS com JSON, sem markdown:
{"pontuacao": <número de 0 a 100>, "categoria": "financeiro"|"trabalho"|"pessoal"|"outro"}

pontuacao: 0 = irrelevante, 100 = urgente ou importante agora.
categoria:
- financeiro: dinheiro, boleto, fatura, pix, cartão, imposto
- trabalho: reunião, prazo, projeto, cliente, entrega
- pessoal: família, saúde, casa, amigos
- outro: o que não se encaixa

Origem: ${origem || "desconhecida"}
Título: ${titulo}
Conteúdo: ${conteudo}`;

  const resposta = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": chave,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-5-5",
      max_tokens: 256,
      effort: "low",
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!resposta.ok) {
    const detalhe = await resposta.text();
    console.error("claude", resposta.status, detalhe.slice(0, 400));
    return json({ erro: "falha na IA" }, 502);
  }

  const payload = await resposta.json();
  const bruto = extrairTexto(payload);
  const lido = lerResultado(bruto);
  if (!lido) {
    console.error("resposta-invalida", bruto);
    return json({ erro: "resposta inválida da IA" }, 502);
  }

  return json({
    pontuacao: Math.min(100, Math.max(0, Math.round(lido.pontuacao))),
    categoria: categoriaValida(lido.categoria),
  });
});

function json(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), { status, headers: cabecalhos });
}

function textoCurto(valor: unknown, maximo: number): string {
  if (typeof valor !== "string") return "";
  return valor.trim().slice(0, maximo);
}

function extrairTexto(payload: { content?: Array<{ text?: string }> }): string {
  return payload.content?.map((bloco) => bloco.text ?? "").join("\n") ?? "";
}

function lerResultado(bruto: string): { pontuacao: number; categoria: string } | null {
  const limpo = bruto.replace(/```json|```/g, "").trim();
  const jsonMatch = limpo.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return null;
  try {
    const lido = JSON.parse(jsonMatch[0]) as { pontuacao?: unknown; categoria?: unknown };
    const pontuacao = Number(lido.pontuacao);
    if (!Number.isFinite(pontuacao) || typeof lido.categoria !== "string") return null;
    return { pontuacao, categoria: lido.categoria };
  } catch {
    return null;
  }
}

function categoriaValida(valor: string): Categoria {
  const normalizado = valor.trim().toLowerCase();
  return (CATEGORIAS as readonly string[]).includes(normalizado)
    ? (normalizado as Categoria)
    : "outro";
}
