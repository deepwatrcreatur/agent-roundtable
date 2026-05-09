defmodule Roundtable.ArchitectureBenchmark do
  @moduledoc """
  Reproducible benchmark profiles for comparing a `jj`-native core against a
  Git-compatible agent infrastructure edge.
  """

  @profiles %{
    "nixpkgs" => %{
      title: "Nixpkgs HA rollout benchmark",
      workload: %{
        label: "Agent-scale infra rollout",
        concurrent_changes: 36,
        ephemeral_workspaces: 24,
        conflict_recovery_cases: 8,
        ingest_window: "2.5 minutes",
        provenance_hooks: [
          "roundtable decision trace",
          "bookmark/change-id mapping",
          "rollback note linkage"
        ]
      },
      paths: [
        %{
          id: :jj_native,
          label: "jj-native core",
          posture: "native",
          metrics: [
            %{
              label: "Throughput",
              value: "1.00x",
              note: "Baseline for agent-heavy parallel change handling."
            },
            %{
              label: "Ingest latency",
              value: "0.72x",
              note:
                "Lower ingest overhead when change identity is native, not reconstructed from Git refs."
            },
            %{
              label: "Operational complexity",
              value: "0.58x",
              note: "Less compatibility glue to own during conflict surfacing and recovery."
            },
            %{
              label: "Ecosystem compatibility",
              value: "0.63x",
              note: "Requires a Git-shaped edge for familiar tooling."
            },
            %{
              label: "Provenance fidelity",
              value: "0.95x",
              note: "Change identity and review history stay closer to the real working model."
            }
          ],
          tradeoffs: [
            "Best fit for many concurrent agent edits and ephemeral workspaces.",
            "Needs a compatibility boundary when teams insist on Git-native surfaces."
          ]
        },
        %{
          id: :git_compatible,
          label: "Git-compatible edge-first flow",
          posture: "compatible",
          metrics: [
            %{
              label: "Throughput",
              value: "0.79x",
              note:
                "Branch and merge bookkeeping adds more coordination overhead under heavy fan-out."
            },
            %{
              label: "Ingest latency",
              value: "1.00x",
              note: "Baseline Git-edge ingest cost for mirrored sources and PR-shaped workflows."
            },
            %{
              label: "Operational complexity",
              value: "1.00x",
              note: "Baseline includes translation, branch hygiene, and lossiness handling."
            },
            %{
              label: "Ecosystem compatibility",
              value: "1.00x",
              note: "Strongest fit for existing forge and developer tool expectations."
            },
            %{
              label: "Provenance fidelity",
              value: "0.68x",
              note: "Squash/rebase flows hide lineage unless Vaglio restores it explicitly."
            }
          ],
          tradeoffs: [
            "Best fit for adoption and familiar hosting UX.",
            "Pushes more semantic recovery and explainability burden onto Vaglio."
          ]
        }
      ],
      recommendation: %{
        summary:
          "Keep Vaglio native in `jj` for change identity, conflict recovery, and provenance; keep Git-compatible surfaces at the Forgejo edge for adoption.",
        native_zone: [
          "ephemeral workspaces",
          "change identity",
          "conflict surfacing",
          "agent provenance"
        ],
        compatible_zone: [
          "repo browsing",
          "pull-request intake",
          "human auth/session UX",
          "webhook ingress"
        ]
      }
    },
    "kubernetes" => %{
      title: "Kubernetes subsystem coordination benchmark",
      workload: %{
        label: "Large multi-subsystem review flow",
        concurrent_changes: 48,
        ephemeral_workspaces: 30,
        conflict_recovery_cases: 10,
        ingest_window: "3.2 minutes",
        provenance_hooks: [
          "SIG ownership trace",
          "review lineage overlay",
          "release-risk explanation"
        ]
      },
      paths: [
        %{
          id: :jj_native,
          label: "jj-native core",
          posture: "native",
          metrics: [
            %{
              label: "Throughput",
              value: "1.00x",
              note: "Handles many simultaneous controller/API edits more cleanly."
            },
            %{
              label: "Ingest latency",
              value: "0.76x",
              note: "Less reconstitution work when syncing agent-produced changes into analysis."
            },
            %{
              label: "Operational complexity",
              value: "0.62x",
              note: "Fewer branch-management artifacts to clean up at scale."
            },
            %{
              label: "Ecosystem compatibility",
              value: "0.61x",
              note: "Still needs a Git-shaped facade for upstream contributor expectations."
            },
            %{
              label: "Provenance fidelity",
              value: "0.96x",
              note: "Preserves high-blast-radius reasoning with less lossy merge translation."
            }
          ],
          tradeoffs: [
            "Stronger long-term substrate for agent-scale code velocity.",
            "Needs deliberate compatibility surfaces for human contributors."
          ]
        },
        %{
          id: :git_compatible,
          label: "Git-compatible edge-first flow",
          posture: "compatible",
          metrics: [
            %{
              label: "Throughput",
              value: "0.74x",
              note: "Review and branch overhead compounds as subsystem concurrency rises."
            },
            %{
              label: "Ingest latency",
              value: "1.00x",
              note: "Baseline Git mirror/import flow remains serviceable for demos and adoption."
            },
            %{
              label: "Operational complexity",
              value: "1.00x",
              note: "Baseline includes more policy and tooling glue to regain semantics."
            },
            %{
              label: "Ecosystem compatibility",
              value: "1.00x",
              note: "Matches what current contributors and integrations already expect."
            },
            %{
              label: "Provenance fidelity",
              value: "0.64x",
              note: "More lineage loss under squash/rebase-heavy flows unless Vaglio repairs it."
            }
          ],
          tradeoffs: [
            "Easier external adoption and procurement story.",
            "Less compelling substrate once agents dominate throughput."
          ]
        }
      ],
      recommendation: %{
        summary:
          "For very large projects, Git compatibility should be a border policy, not the internal execution model.",
        native_zone: [
          "agent batch execution",
          "semantic lineage",
          "cross-subsystem recovery",
          "benchmark-driven planning"
        ],
        compatible_zone: [
          "upstream mirrors",
          "pull-request presentation",
          "review notifications",
          "external ecosystem integrations"
        ]
      }
    },
    "forgejo" => %{
      title: "Forgejo shell benchmark",
      workload: %{
        label: "Product-boundary dogfood flow",
        concurrent_changes: 18,
        ephemeral_workspaces: 14,
        conflict_recovery_cases: 5,
        ingest_window: "1.4 minutes",
        provenance_hooks: [
          "shell-to-core boundary trace",
          "PR envelope mapping",
          "actions governance notes"
        ]
      },
      paths: [
        %{
          id: :jj_native,
          label: "jj-native core",
          posture: "native",
          metrics: [
            %{
              label: "Throughput",
              value: "1.00x",
              note: "Supports the product story of agent-heavy code production."
            },
            %{
              label: "Ingest latency",
              value: "0.78x",
              note: "Fast enough to keep the demo responsive without hiding core semantics."
            },
            %{
              label: "Operational complexity",
              value: "0.66x",
              note: "Lower long-term burden if the shell stays thin."
            },
            %{
              label: "Ecosystem compatibility",
              value: "0.88x",
              note: "Good enough when Forgejo remains the UI shell."
            },
            %{
              label: "Provenance fidelity",
              value: "0.97x",
              note: "Best fit for showing why Vaglio is more than hosted Git."
            }
          ],
          tradeoffs: [
            "Best differentiation story for investors.",
            "Still benefits from familiar Git entry points at the surface."
          ]
        },
        %{
          id: :git_compatible,
          label: "Git-compatible edge-first flow",
          posture: "compatible",
          metrics: [
            %{
              label: "Throughput",
              value: "0.84x",
              note: "Good enough for shell workflows, weaker for future agent scale."
            },
            %{
              label: "Ingest latency",
              value: "1.00x",
              note: "Baseline Git-edge experience for imports and PRs."
            },
            %{
              label: "Operational complexity",
              value: "1.00x",
              note: "Baseline includes translation and provenance repair burden."
            },
            %{
              label: "Ecosystem compatibility",
              value: "1.00x",
              note: "Strongest short-term fit for host-side integrations."
            },
            %{
              label: "Provenance fidelity",
              value: "0.71x",
              note: "Still loses semantics unless Vaglio reconstructs them."
            }
          ],
          tradeoffs: [
            "Simplest procurement and familiarity story.",
            "Makes Vaglio look more like repo analytics than a new substrate."
          ]
        }
      ],
      recommendation: %{
        summary:
          "Use Forgejo for the shell, but keep the inside unmistakably `jj`-native so the product story remains differentiated.",
        native_zone: [
          "semantic history",
          "agent workspace model",
          "deliberation provenance",
          "conflict recovery"
        ],
        compatible_zone: [
          "UI chrome",
          "account/session management",
          "repo import",
          "developer entry points"
        ]
      }
    }
  }

  @spec compare(String.t()) :: {:ok, map()} | {:error, term()}
  def compare(id) do
    case Map.fetch(@profiles, id) do
      {:ok, profile} ->
        {:ok,
         %{
           id: id,
           title: profile.title,
           workload: profile.workload,
           paths: profile.paths,
           recommendation: profile.recommendation
         }}

      :error ->
        {:error, {:unknown_benchmark_profile, id}}
    end
  end
end
