###############################
# 01_falling_block_iso_viscous NR.02-24
# simple setup to simulate a dense viscous sphere falling down a less viscous medium
#
#
# if you have blue wavy underline below the model definition lines add this to the settings.json in the top left: "julia.lint.call": false
###############################


# load needed packages, GeophysicalModelGenerator is used to create shapes for the starting modelling conditions, GMT is used to import toppography, Plots is used to plot model before running the simulation
using LaMEM, GeophysicalModelGenerator,  Plots


# directory you want your simulation's output to be saved in
out_dir = "output"

# Below we create a structure to define the modelling setup
model = Model(   
                # Scaling paramters, this ensure non-dimensionalisation in LaMEM but also gives the units to the outputs, you should not have to touch it 
                Scaling( NO_units()),

                # This is where you setup the size of your model (as km as set above) and the resolution. e.g., x = [minX, maxX] (...)
                Grid(               x               = [0.0,1.0],
                                    y               = [0.0,1.0],               # notice here that y is only 2km as we want to run a 2D simulation
                                    z               = [0.0,1.0],
                                    nel             = (32,32,32) ),              # notice that only one element is given in the y-direction to effectively have a 2D simulation

                # set timestepping parameters
                Time(               time_end        = 200.0,                     # Time is always expressed in Myrs (input/output definition)
                                    dt              = 10.0,                     # Target timestep, here 10k years
                                    dt_min          = 0.00001,                 # Minimum dt allowed, this is useful for more complex simulations
                                    dt_max          = 200,                      # max dt, here 100k years
                                    dt_out          = 0.1,
                                    inc_dt          = 0.1,
                                    nstep_max       = 20,                       # Number of wanted timesteps
                                    nstep_out       = 1 ),                      # save output every nstep_out

                # set solution parameters
                SolutionParams(     FSSA            = 1.0,                   # free surface stabilization parameter [0 - 1]
                                    init_guess      = 0,                     # initial guess flag
                                    eta_min         = 1.0,
                                    eta_ref         = 1.0,
                                    eta_max         = 1000.0 ),

                # what will be saved in the output of the simulation
                Output(             
                                    out_pvd             = 1,       	        # activate writing .pvd file
                                    out_j2_dev_stress   = 1,			    # second invariant of stress tensor
                                    out_strain_rate     = 1,			    # strain rate tensor
                                    out_j2_strain_rate  = 1,		        # second invariant of strain rate tensor
                                    out_avd             = 1,                # activate AVD phase output
                                    out_avd_pvd         = 1,                # activate writing .pvd file
                                    out_avd_ref         = 3,                # AVD grid refinement factor
                                    out_dir             = out_dir ),

                # here we define the options for the solver, it is advised to no fiddle with this (only comment "-da_refine_y 1" for 3D simulations)
                Solver(             SolverType 			=	"multigrid",  	# solver [direct or multigrid]
                                    MGLevels 			=	4,			    # number of MG levels [default=3]
                                    MGSweeps 			=	10,			    # number of MG smoothening steps per level [default=10]
                                    MGSmoother 			=	"chebyshev", 	# type of smoothener used [chebyshev or jacobi]
                                    MGCoarseSolver 		=	"mumps", 		# coarse grid solver [direct/superlu_dist/superlu_dist or redundant - more options specifiable through the command-line options -crs_ksp_type & -crs_pc_type]
                                    PETSc_options       = [ "-snes_type ksponly",
                                                            "-js_ksp_monitor",
                                                            "-crs_pc_type bjacobi"
                                                         ]
                        )  
            )  

#=================== define phases (different materials) of the model ==========================#

model.Grid.Phases                      .= 0;                        # here we first define the background phase id = 0

add_box!(model; xlim=(0.75, 0.9), 
                ylim=(0.75, 0.9), 
                zlim=(0.75, 0.9),
                phase               = ConstantPhase(1) )

add_box!(model; xlim=(0.25, 0.5), 
                ylim=(0.25, 0.5), 
                zlim=(0.25, 0.5),
                phase               = ConstantPhase(2) )
        
#====================== define material properties of the phases ============================#

matrix = Phase(         Name            = "matrix",                 # let's call phase 0 mantle
                        ID              = 0,                        # not that ID here points to phase 0 which is the background phase defined above
                        rho             = 1.0,                     # set mantle density
                        eta             = 1.0 );                   # set elastic modulii

block1 = Phase(         Name            = "block1",
                        ID              = 1,
                        rho             = 2.0,
                        eta             = 1000.0 );

block2 = Phase(         Name            = "block2",
                        ID              = 2,
                        rho             = 2.0,
                        eta             = 100.0 );

add_phase!( model, matrix, block1, block2)                                      # this adds the phases to the model structure

plot_cross_section(model, y=0.5, field=:phase)
savefig("falling_block_3D.png")

#=============================== perform simulation ===========================================#

run_lamem(model, 2)
