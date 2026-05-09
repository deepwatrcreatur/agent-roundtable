defmodule RoundtableWeb.LandingLive do
  @moduledoc """
  Public-facing landing surface that introduces the shareable Forgejo shell demo.
  """

  use Phoenix.LiveView

  alias Roundtable.InvestorDemo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:recommended_demo, recommended_demo())
     |> assign(:demo_catalog, InvestorDemo.catalog())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 1100px; margin: 0 auto; padding: 2.5rem 1rem 4rem;">
      <section style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; align-items: center; margin-bottom: 2.5rem;">
        <div>
          <div style="display: inline-flex; align-items: center; gap: 0.5rem; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; color: #58a6ff; font-size: 0.76rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 1rem;">
            Shareable demo surface
          </div>
          <h1 style="font-size: clamp(2.2rem, 6vw, 3.8rem); line-height: 1.02; color: #f0f6fc; margin-bottom: 0.9rem;">
            Forgejo outside.
            <br />
            Vaglio semantics inside.
          </h1>
          <p style="color: #8b949e; line-height: 1.65; font-size: 1rem; max-width: 42rem; margin-bottom: 1.25rem;">
            This prototype shows how a familiar Forgejo-shaped code host can front a more opinionated
            Vaglio layer for provenance, deliberation, and investor-readable repository analysis.
          </p>
          <div style="display: flex; gap: 0.75rem; flex-wrap: wrap; margin-bottom: 1rem;">
            <a href={"/forgejo-shell?demo=#{@recommended_demo.id}"} style={cta_style(:primary)}>
              Open Recommended Demo
            </a>
            <a href="/roundtable" style={cta_style(:secondary)}>
              Open Roundtable Ops
            </a>
          </div>
          <p style="color: #8b949e; font-size: 0.84rem; line-height: 1.5;">
            Start with <strong style="color: #c9d1d9;">{@recommended_demo.name}</strong> if you want the quickest product read.
          </p>
        </div>

        <div style="background: linear-gradient(180deg, rgba(22,27,34,0.96), rgba(13,17,23,0.96)); border: 1px solid #30363d; border-radius: 18px; padding: 1.25rem; box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);">
          <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.75rem;">
            What this page is for
          </div>
          <div style="display: grid; gap: 0.75rem;">
            <.ownership_card
              title="Forgejo owns"
              detail="Repository browsing, pull-request familiarity, and the shell people already know how to navigate."
            />
            <.ownership_card
              title="Vaglio owns"
              detail="Semantic change projection, provenance overlays, benchmark framing, and the product story around agent-scale software work."
            />
            <.ownership_card
              title="Click first"
              detail="The recommended demo opens a curated imported repo, the investor dashboard, and the jj-vs-Git benchmark in one place."
            />
          </div>
        </div>
      </section>

      <section style="margin-bottom: 2.5rem;">
        <h2 style={section_heading_style()}>Recommended Demo Path</h2>
        <div style="background: #161b22; border: 1px solid #30363d; border-radius: 14px; padding: 1rem;">
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 1rem; align-items: start;">
            <div>
              <div style="color: #f0f6fc; font-size: 1.05rem; font-weight: 700; margin-bottom: 0.4rem;">
                {@recommended_demo.name}
              </div>
              <p style="color: #8b949e; line-height: 1.55; margin-bottom: 0.8rem;">
                {@recommended_demo.teaser}
              </p>
              <a href={"/forgejo-shell?demo=#{@recommended_demo.id}"} style={cta_style(:primary)}>
                Launch this demo
              </a>
            </div>
            <div>
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.45rem;">
                Why this one
              </div>
              <ul style="margin: 0; padding-left: 1rem; color: #8b949e; line-height: 1.7;">
                <li>Shows the Forgejo shell and Vaglio boundary immediately.</li>
                <li>Includes a curated investor-facing dashboard, not just a repo browser.</li>
                <li>Exposes the jj-native recommendation without forcing the reader through internal ops UI first.</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      <section>
        <h2 style={section_heading_style()}>Other Curated Demos</h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 0.75rem;">
          <a
            :for={demo <- @demo_catalog}
            href={"/forgejo-shell?demo=#{demo.id}"}
            style="display: block; text-decoration: none; background: #161b22; border: 1px solid #30363d; border-radius: 12px; padding: 1rem;"
          >
            <div style="color: #f0f6fc; font-weight: 600; margin-bottom: 0.35rem;">{demo.name}</div>
            <div style="color: #58a6ff; font-size: 0.78rem; margin-bottom: 0.45rem;">{demo.source_label}</div>
            <div style="color: #8b949e; line-height: 1.5; font-size: 0.88rem;">{demo.teaser}</div>
          </a>
        </div>
      </section>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :detail, :string, required: true

  defp ownership_card(assigns) do
    ~H"""
    <div style="background: rgba(13,17,23,0.82); border: 1px solid #30363d; border-radius: 12px; padding: 0.9rem;">
      <div style="color: #f0f6fc; font-weight: 600; margin-bottom: 0.35rem;">{@title}</div>
      <div style="color: #8b949e; line-height: 1.55; font-size: 0.88rem;">{@detail}</div>
    </div>
    """
  end

  defp recommended_demo do
    InvestorDemo.catalog()
    |> Enum.find(fn demo -> demo.id == "forgejo" end)
    |> Kernel.||(List.first(InvestorDemo.catalog()))
  end

  defp section_heading_style do
    "font-size: 0.9rem; color: #8b949e; margin-bottom: 0.9rem; text-transform: uppercase; letter-spacing: 0.08em;"
  end

  defp cta_style(:primary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: #238636; color: #f0f6fc; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #2ea043;"
  end

  defp cta_style(:secondary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: transparent; color: #c9d1d9; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #30363d;"
  end
end
