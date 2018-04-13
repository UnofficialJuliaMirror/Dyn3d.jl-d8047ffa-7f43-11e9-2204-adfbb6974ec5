module ConfigDataType

export ConfigBody, ConfigJoint, Dof, Motions

import Base: show

#-------------------------------------------------------------------------------
# motion parameters to describe a motion
struct Motions
    motion_type::String
    motion_params::Vector{Float64}
end

Motions() = Motions("", [])
#-------------------------------------------------------------------------------
# single dof information for every dof in a joint
struct Dof
    dof_id::Int
    dof_type::String
    stiff::Float64
    damp::Float64
    motion::Motions
end

Dof() = Dof(3, "passive", 0.03, 0.01, Motions())
#-------------------------------------------------------------------------------
# configuration properties of a single body
struct ConfigBody
    nbody::Int
    nverts::Int
    verts::Array{Float64,2}
    ρ::Float64
end

ConfigBody(nbody) = ConfigBody(nbody, 4,
    [0. 0.; 1. 0.; 1. 1./nbody; 0. 1./nbody], 0.01)

function show(io::IO, m::ConfigBody)
    println(io, " nbody=$(m.nbody)")
    println(io, " nverts=$(m.nverts)")
    println(io, " verts=$(m.verts)")
    println(io, " ρ=$(m.ρ)")
end

#-------------------------------------------------------------------------------
# configuration properties of a single joint
struct ConfigJoint
    njoint::Int
    joint_id::Int
    joint_type::String
    shape1::Vector{Float64}
    shape2::Vector{Float64}
    body1::Int
    joint_dof::Vector{Dof}
    qJ_init::Vector{Float64}
end

ConfigJoint(njoint,joint_type) = ConfigJoint(njoint, 1, joint_type,
    [0., 0., 0., 1./njoint, 0., 0.], zeros(Float64,6),
    0, [Dof()], zeros(Float64,6))

function show(io::IO, m::ConfigJoint)
    println(io, " joint_type=$(m.joint_type)")
end


end
