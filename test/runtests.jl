using Test, Pkg

ENV["DATADEPS_ALWAYS_ACCEPT"] = true
ENV["JULIA_LOG_LEVEL"] = "WARN"

for submodule in ["Utilities/TicToc",
                  "Utilities/VariableTemplates",
                  "Utilities/ParametersType",
                  "Utilities/RootSolvers",
                  "Common/PlanetParameters",
                  "Common/MoistThermodynamics",
                  "Atmos/Parameterizations/SurfaceFluxes",
                  "Atmos/Parameterizations/TurbulenceConvection",
                  "Atmos/Parameterizations/Microphysics",
                  "Mesh",
                  "DGmethods",
                  "Diagnostics",
                  "ODESolvers",
                  "Ocean",
                  "Arrays",
                  "LinearSolvers",
                  "Driver",
                 ]

  println("Starting tests for $submodule")
  t = @elapsed include(joinpath(submodule,"runtests.jl"))
  println("Completed tests for $submodule, $(round(Int, t)) seconds elapsed")
end
