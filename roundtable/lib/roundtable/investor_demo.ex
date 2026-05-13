defmodule Roundtable.InvestorDemo do
  @moduledoc """
  Curated public-repository demo profiles for the investor-facing prototype.

  Each profile represents a public source repository plus the Forgejo-hosted
  import target that Vaglio presents inside the prototype shell.
  """

  @default_base_url "https://codeberg.org"

  @profiles [
    %{
      id: "nixpkgs",
      name: "NixOS/nixpkgs",
      teaser:
        "Massive infra codebase with broad subsystem ownership and frequent coordination churn.",
      source: %{
        label: "GitHub source",
        slug: "NixOS/nixpkgs",
        url: "https://github.com/NixOS/nixpkgs"
      },
      import_target: %{
        repo_slug: "vaglio-demos/nixpkgs",
        default_branch: "master",
        head_ref: "feature/ha-router-rollout",
        commit_sha: "deadbeef",
        pull_number: 1204,
        merge_strategy: :rebase,
        pull_title: "HA router and DNS failover hardening"
      },
      dashboard: %{
        headline: "Operational complexity with concentrated review bottlenecks.",
        narrative:
          "Vaglio highlights which maintainers absorb the coordination load, where routing and platform changes pile up, and how much of the rollout reasoning is already captured versus still trapped in chat.",
        metrics: [
          %{
            label: "Maintainer concentration",
            value: "0.61",
            note: "Top 5 maintainers touch 61% of critical platform paths."
          },
          %{
            label: "Contributor expertise signals",
            value: "14",
            note:
              "Fourteen contributors show repeated authorship in networking, NixOS modules, and release plumbing."
          },
          %{
            label: "Subsystem hotspots",
            value: "3",
            note: "Networking, stdenv, and module evaluation dominate recent coordination cost."
          }
        ],
        hotspots: [
          %{
            area: "Networking / routers",
            signal: "Cross-host change coupling",
            note: "Changes to HA failover, firewalling, and DNS overlap across multiple machines."
          },
          %{
            area: "Module evaluation",
            signal: "Review latency",
            note: "High reviewer load spikes when infra-wide options change."
          },
          %{
            area: "Release plumbing",
            signal: "Escalating rollback cost",
            note:
              "Operational fixes often need provenance and rollout notes, not just code diffs."
          }
        ],
        expertise_signals: [
          %{
            title: "Infrastructure stewards",
            detail:
              "Repeat edits across router, secrets, and NixOS module surfaces signal high operational context."
          },
          %{
            title: "Evaluation specialists",
            detail:
              "A smaller group consistently resolves failures tied to module graph and build-system edges."
          }
        ],
        provenance: [
          %{
            title: "Deliberation overlay",
            detail:
              "Link HA router changes to the exact roundtable discussions and rollout rationale that shaped them."
          },
          %{
            title: "JJ-native review layer",
            detail:
              "Keep Git/Forgejo at the edge while preserving `jj`-level change identity for agent-heavy work."
            }
        ],
        stress: %{
          headline: "Prediction error clusters around infra-wide rollout paths.",
          narrative:
            "The first-pass stress model treats contested, high-blast-radius paths as high prediction error and stable, well-vouched paths as low prediction error. It complements raw churn by showing where coordination pressure is compounding rather than merely changing.",
          metrics: [
            %{
              label: "Branch stress",
              value: "0.78",
              note: "The HA router rollout branch bundles multiple tightly coupled infra surfaces."
            },
            %{
              label: "History heat",
              value: "3 peaks",
              note: "Networking, module evaluation, and release plumbing each show repeated stress spikes."
            },
            %{
              label: "Active-inference confidence",
              value: "medium",
              note: "Enough structured evidence exists to rank hotspots, but not yet enough provenance to collapse uncertainty."
            }
          ],
          hotspots: [
            %{
              title: "router failover path",
              detail:
                "High precision operators disagree across firewall, DHCP, and DNS coupling, so contention remains costly even when code size is modest.",
              stress: "high",
              heat: "0.86"
            },
            %{
              title: "module evaluation path",
              detail:
                "Repeated evaluation regressions signal unresolved model mismatch rather than one-off patch churn.",
              stress: "high",
              heat: "0.81"
            },
            %{
              title: "release plumbing path",
              detail:
                "Rollout notes and provenance reduce surprise, but the path still spikes when fixes arrive under time pressure.",
              stress: "medium",
              heat: "0.63"
            }
          ],
          history: [
            %{
              window: "T-21d",
              pressure: "Escalating coordination",
              note: "Routing and DNS changes begin to overlap in the same rollout slice."
            },
            %{
              window: "T-7d",
              pressure: "Peak contention",
              note: "Evaluation failures and rollback planning stack on the same branch."
            },
            %{
              window: "T-1d",
              pressure: "Partial stabilization",
              note: "Operational notes land, but a few high-cost review surfaces remain contested."
            }
          ]
        }
      }
    },
    %{
      id: "kubernetes",
      name: "kubernetes/kubernetes",
      teaser:
        "Large-scale upstream project with many subsystems, strong reviewer specialization, and obvious hotspot surfaces.",
      source: %{
        label: "GitHub source",
        slug: "kubernetes/kubernetes",
        url: "https://github.com/kubernetes/kubernetes"
      },
      import_target: %{
        repo_slug: "vaglio-demos/kubernetes",
        default_branch: "master",
        head_ref: "feature/controller-observability",
        commit_sha: "cafebabe",
        pull_number: 884,
        merge_strategy: :squash,
        pull_title: "Controller observability and ownership tracing"
      },
      dashboard: %{
        headline: "Subsystem sprawl with highly specialized reviewer clusters.",
        narrative:
          "The investor story is not just repo analytics. Vaglio shows where controller, API machinery, and release engineering knowledge is concentrated, and where agent output needs durable provenance to stay governable.",
        metrics: [
          %{
            label: "Maintainer concentration",
            value: "0.47",
            note:
              "Top maintainers are less dominant overall, but critical subsystems still hinge on a narrow review core."
          },
          %{
            label: "Contributor expertise signals",
            value: "21",
            note: "A deep bench exists, but expertise is partitioned by subsystem."
          },
          %{
            label: "Subsystem hotspots",
            value: "4",
            note:
              "API machinery, controllers, test-infra, and release tooling dominate coordination heat."
          }
        ],
        hotspots: [
          %{
            area: "API machinery",
            signal: "Architectural blast radius",
            note:
              "Schema and compatibility changes ripple across client, server, and docs surfaces."
          },
          %{
            area: "Controllers",
            signal: "High churn density",
            note: "Frequent logic changes make ownership continuity especially valuable."
          },
          %{
            area: "Release tooling",
            signal: "Human bottleneck",
            note:
              "Investor-facing story: Vaglio shortens the path from change to trustworthy rollout narrative."
          }
        ],
        expertise_signals: [
          %{
            title: "SIG-aligned expertise",
            detail: "Contributor clusters map cleanly to subsystem-specific knowledge pockets."
          },
          %{
            title: "Reviewer continuity",
            detail:
              "A small set of people repeatedly stabilizes the same risky surfaces across release cycles."
          }
        ],
        provenance: [
          %{
            title: "Roundtable-backed triage",
            detail:
              "Attach decision history to high-blast-radius changes before they reach release coordination."
          },
          %{
            title: "Lossy Git merge surfacing",
            detail:
              "Show where squash/rebase hides lineage so reviewers know when extra explanation is required."
            }
        ],
        stress: %{
          headline: "Stress concentrates where subsystem specialization meets release obligations.",
          narrative:
            "The active-inference view highlights controller and API machinery paths where small contributor pools must absorb high ambiguity under strong compatibility constraints.",
          metrics: [
            %{
              label: "Branch stress",
              value: "0.69",
              note: "Cross-SIG changes amplify review contention even when overall ownership is broad."
            },
            %{
              label: "History heat",
              value: "4 peaks",
              note: "API machinery, controllers, release tooling, and test-infra recur as pressure zones."
            },
            %{
              label: "Active-inference confidence",
              value: "high",
              note: "Maintainer specialization patterns are strong enough to make the hotspot ranking legible."
            }
          ],
          hotspots: [
            %{
              title: "api machinery path",
              detail:
                "Compatibility obligations create repeated prediction error whenever controller-facing schema assumptions move.",
              stress: "high",
              heat: "0.84"
            },
            %{
              title: "controller logic path",
              detail:
                "Fast-moving control loops create dense change history, but only some of that churn resolves underlying uncertainty.",
              stress: "high",
              heat: "0.79"
            },
            %{
              title: "release tooling path",
              detail:
                "Stress rises when release readiness depends on a narrow operational review core.",
              stress: "medium",
              heat: "0.66"
            }
          ],
          history: [
            %{
              window: "T-30d",
              pressure: "Subsystem drift",
              note: "Independent changes appear safe locally but begin to accumulate cross-cutting review cost."
            },
            %{
              window: "T-10d",
              pressure: "Compatibility crunch",
              note: "Schema, controller, and release concerns converge on the same merge window."
            },
            %{
              window: "T-2d",
              pressure: "Review compression",
              note: "A small reviewer set absorbs most of the remaining uncertainty before release."
            }
          ]
        }
      }
    },
    %{
      id: "forgejo",
      name: "forgejo/forgejo",
      teaser:
        "A self-hosted forge codebase that makes the product boundary itself easy to demonstrate.",
      source: %{
        label: "Codeberg source",
        slug: "forgejo/forgejo",
        url: "https://codeberg.org/forgejo/forgejo"
      },
      import_target: %{
        repo_slug: "vaglio-demos/forgejo",
        default_branch: "forgejo",
        head_ref: "feature/vaglio-shell",
        commit_sha: "8badf00d",
        pull_number: 66,
        merge_strategy: :merge,
        pull_title: "Vaglio shell integration"
      },
      dashboard: %{
        headline: "Product dogfooding story: Forgejo shell outside, Vaglio semantics inside.",
        narrative:
          "This demo makes the platform story concrete: repository browsing and account UX stay Forgejo-native while Vaglio adds semantic change tracking, provenance, and analysis surfaces beside it.",
        metrics: [
          %{
            label: "Maintainer concentration",
            value: "0.54",
            note: "A modest core still anchors critical forge workflows."
          },
          %{
            label: "Contributor expertise signals",
            value: "9",
            note: "UI, auth, federation, and actions each show repeat expert contributors."
          },
          %{
            label: "Subsystem hotspots",
            value: "3",
            note: "Web UI, repository APIs, and actions runners drive most coordination cost."
          }
        ],
        hotspots: [
          %{
            area: "Repository APIs",
            signal: "Compatibility surface",
            note: "This is where Git-shaped clients meet a more expressive internal model."
          },
          %{
            area: "Web UI",
            signal: "Product leverage",
            note: "UI chrome can be reused while Vaglio adds differentiated analysis."
          },
          %{
            area: "Actions / runners",
            signal: "Automation governance",
            note: "A natural place to show agent-scale provenance and control loops."
          }
        ],
        expertise_signals: [
          %{
            title: "Self-hosting credibility",
            detail:
              "Investors can see the product demonstrated on the very kind of platform it complements."
          },
          %{
            title: "Boundary clarity",
            detail:
              "The shell shows which features remain Forgejo-native versus which become Vaglio-native."
          }
        ],
        provenance: [
          %{
            title: "Imported source + local semantics",
            detail:
              "Public upstream stays recognizable while imported analysis preserves a `jj`-first internal history."
          },
          %{
            title: "Decision traceability",
            detail: "Overlay roundtable and review context on top of Forgejo pull-request flows."
            }
        ],
        stress: %{
          headline: "Product-boundary stress is lowest where Forgejo stays native and Vaglio stays semantic.",
          narrative:
            "This demo frames stress as the cost of forcing one layer to impersonate the other. Heat is highest where repository APIs, UI expectations, and automation governance overlap.",
          metrics: [
            %{
              label: "Branch stress",
              value: "0.58",
              note: "Most uncertainty is architectural rather than operational: where should the semantic boundary live?"
            },
            %{
              label: "History heat",
              value: "3 peaks",
              note: "Repository APIs, web UI, and actions automation carry most of the integration pressure."
            },
            %{
              label: "Active-inference confidence",
              value: "medium-high",
              note: "Boundary clarity reduces stress faster than raw code churn reduction in this demo."
            }
          ],
          hotspots: [
            %{
              title: "repository api path",
              detail:
                "Heat appears where Git-facing expectations must be translated into a richer internal model without confusing operators.",
              stress: "high",
              heat: "0.74"
            },
            %{
              title: "web shell path",
              detail:
                "UI reuse is valuable, but stress rises if product boundaries are hidden instead of made explicit.",
              stress: "medium",
              heat: "0.61"
            },
            %{
              title: "actions governance path",
              detail:
                "Agent-scale automation needs provenance and policy hooks or the apparent convenience becomes latent operational debt.",
              stress: "medium",
              heat: "0.64"
            }
          ],
          history: [
            %{
              window: "T-14d",
              pressure: "Prototype ambiguity",
              note: "The shell can demo well before the semantic boundary is fully explained."
            },
            %{
              window: "T-5d",
              pressure: "Boundary clarification",
              note: "Separating Forgejo-native and Vaglio-native surfaces reduces confusion and lowers stress."
            },
            %{
              window: "T-1d",
              pressure: "Governance follow-through",
              note: "The remaining heat sits in policy and provenance, not basic routing or host availability."
            }
          ]
        }
      }
    }
  ]

  @spec catalog() :: [map()]
  def catalog do
    Enum.map(@profiles, fn profile ->
      %{
        id: profile.id,
        name: profile.name,
        teaser: profile.teaser,
        source_label: profile.source.label,
        source_slug: profile.source.slug
      }
    end)
  end

  @spec default_id() :: String.t()
  def default_id do
    @profiles
    |> Enum.find(hd(@profiles), &(&1.id == "forgejo"))
    |> Map.fetch!(:id)
  end

  @spec import(String.t(), keyword() | map()) :: {:ok, map()} | {:error, term()}
  def import(id, opts \\ []) do
    options = normalize_options(opts)

    with {:ok, profile} <- fetch_profile(id) do
      base_url =
        options
        |> Map.get(:base_url, @default_base_url)
        |> to_string()
        |> String.trim()
        |> case do
          "" -> @default_base_url
          value -> value
        end

      {:ok,
       %{
         id: profile.id,
         name: profile.name,
         teaser: profile.teaser,
         source: profile.source,
         imported_repo: %{
           base_url: base_url,
           repo_url:
             String.trim_trailing(base_url, "/") <> "/" <> profile.import_target.repo_slug,
           tree_url:
             String.trim_trailing(base_url, "/") <>
               "/" <>
               profile.import_target.repo_slug <>
               "/src/branch/" <> profile.import_target.default_branch,
           slug: profile.import_target.repo_slug
         },
         shell_inputs: Map.put(profile.import_target, :base_url, base_url),
         import_steps: import_steps(profile),
         dashboard: profile.dashboard
       }}
    end
  end

  defp import_steps(profile) do
    [
      %{
        step: "Import public source",
        status: :done,
        detail:
          "Mirror #{profile.source.slug} into a Forgejo-hosted demo namespace without bespoke setup."
      },
      %{
        step: "Translate Git edge to jj semantics",
        status: :done,
        detail:
          "Project refs, pull requests, and merges through the Git↔jj gateway before analysis."
      },
      %{
        step: "Render investor dashboard",
        status: :done,
        detail:
          "Expose maintainer concentration, expertise signals, hotspots, provenance overlays, and the first stress/heat surface on the same host."
      }
    ]
  end

  defp fetch_profile(id) do
    case Enum.find(@profiles, &(&1.id == id)) do
      nil -> {:error, {:unknown_demo_repo, id}}
      profile -> {:ok, profile}
    end
  end

  defp normalize_options(opts) when is_list(opts), do: Map.new(opts)
  defp normalize_options(opts) when is_map(opts), do: opts
end
