import Base:get, length, show

export CosDict, CosString, CosNumeric, CosBoolean, CosTrue, CosFalse,
       CosObject, CosNull, CosNullType,CosFloat, CosInt, CosArray, CosName,
       CosDict, CosIndirectObjectRef, CosStream, get, set!

@compat abstract type CosObject end

@inline get{T<:CosObject}(o::T)=o.val

@compat abstract type CosString <: CosObject end
@compat abstract type CosNumeric <: CosObject end

@compat struct CosBoolean <: CosObject
    val::Bool
end

const CosTrue=CosBoolean(true)
const CosFalse=CosBoolean(false)

@compat struct CosNullType <: CosObject end

const CosNull=CosNullType()

@compat struct CosFloat <: CosNumeric
    val::Float64
end

@compat struct CosInt <: CosNumeric
    val::Int
end

show(io::IO, o::CosObject) = print(io, o.val)

show(io::IO, o::CosNullType) = print(io, "null")

"""
A parsed data structure to ensure the object information is stored as an object.
This has no meaning without a associated CosDoc. When a reference object is hit
the object should be searched from the CosDoc and returned.
"""
@compat struct CosIndirectObjectRef <: CosObject
  val::Tuple{Int,Int}
  CosIndirectObjectRef(num::Int, gen::Int)=new((num,gen))
end

show(io::IO, o::CosIndirectObjectRef) = @printf io "%d %d R" o.val[1] o.val[2]

#hash(o::CosIndirectObjectRef, h::UInt=zero(UInt)) = hash(o.val, h)
#isequal(r1::CosIndirectObjectRef, r2::CosIndirectObjectRef) = isequal(r1.val, r2.val)

@compat mutable struct CosIndirectObject{T <: CosObject} <: CosObject
  num::Int
  gen::Int
  obj::T
end

get(o::CosIndirectObject) = get(o.obj)

showref(io::IO, o::CosIndirectObject) = @printf io "%d %d R" o.num o.gen

showref(io::IO, o::CosObject)=show(io, o)

function show(io::IO, o::CosIndirectObject)
  str = @sprintf "%d %d obj\n" o.num o.gen
  print(io, str)
  show(io, o.obj)
end

@compat struct CosName <: CosObject
    val::Symbol
    CosName(str::String)=new(Symbol("CosName_",str))
end

function show(io::IO, o::CosName)
  val = String(o.val)
  val = split(val,'_')[2]
  str = @sprintf "/%s" val
  print(io, str)
end

@compat struct CosXString <: CosString
  val::Vector{UInt8}
  CosXString(arr::Vector{UInt8})=new(arr)
end

function show(io::IO, o::CosXString)
  str = @sprintf "%s" "<"*String(copy(o.val))*">"
  print(io, str)
end

Base.convert(::Type{Vector{UInt8}}, xstr::CosXString)=
  (xstr.val |> String |> hex2bytes)

Base.convert(::Type{String}, xstr::CosXString)=
  String(convert(Vector{UInt8},xstr))


@compat struct CosLiteralString <: CosString
    val::Vector{UInt8}
    CosLiteralString(arr::Vector{UInt8})=new(arr)
end

CosLiteralString(str::AbstractString)=CosLiteralString(transcode(UInt8,str))

function show(io::IO, o::CosLiteralString)
  str = @sprintf "%s" "("*String(copy(o.val))*")"
  print(io, str)
end

Base.convert(::Type{Vector{UInt8}}, str::CosLiteralString)=copy(str.val)

Base.convert(::Type{String}, str::CosLiteralString)=
  String(convert(Vector{UInt8},str))

@compat mutable struct CosArray <: CosObject
    val::Array{CosObject,1}
    function CosArray(arr::Array{T,1} where {T<:CosObject})
      val = Array{CosObject,1}()
      for v in arr
        push!(val,v)
      end
      new(val)
    end
    CosArray()=new(Array{CosObject,1}())
end

function show(io::IO, o::CosArray)
  print(io, '[')
  for obj in o.val
    showref(io, obj)
    print(io, ' ')
  end
  print(io, ']')
end

get(o::CosArray, isNative=false)=isNative ? map((x)->get(x),o.val) : o.val
length(o::CosArray)=length(o.val)

@compat mutable struct CosDict <: CosObject
    val::Dict{CosName,CosObject}
    CosDict()=new(Dict{CosName,CosObject}())
end

get(dict::CosDict, name::CosName)=get(dict.val,name,CosNull)

get(o::CosIndirectObject{CosDict}, name::CosName) = get(o.obj, name)

function show(io::IO, o::CosDict)
  print(io, "<<\n")
  for key in keys(o.val)
    print(io, "\t")
    show(io, key)
    print(io, "\t")
    showref(io, get(o,key))
    println(io, "")
  end
  print(io, ">>")
end

"""
Set the value to object. If the object is CosNull the key is deleted.
"""
function set!(dict::CosDict, name::CosName, obj::CosObject)
  if (obj === CosNull)
    return delete!(dict.val,name)
  else
    dict.val[name] = obj
    return dict
  end
end

set!(o::CosIndirectObject{CosDict}, name::CosName, obj::CosObject) =
            set!(o.obj, name, obj)

@compat mutable struct CosStream <: CosObject
    extent::CosDict
    isInternal::Bool
    CosStream(d::CosDict,isInternal::Bool=true)=new(d,isInternal)
end

function show(io::IO, stm::CosStream)
  show(io, stm.extent);
  print(io, "stream\n...\nendstream\n")
end

get(stm::CosStream, name::CosName) = get(stm.extent, name)

get(o::CosIndirectObject{CosStream}, name::CosName) = get(o.obj,name)

set!(stm::CosStream, name::CosName, obj::CosObject)=
    set!(stm.extent, name, obj)

set!(o::CosIndirectObject{CosStream}, name::CosName, obj::CosObject)=
    set!(o.obj,name,obj)

"""
Decodes the stream and provides output as an BufferedInputStream.
"""
get(stm::CosStream) = decode(stm)

@compat mutable struct CosObjectStream <: CosObject
  stm::CosStream
  n::Int
  first::Int
  oids::Vector{Int}
  oloc::Vector{Int}
  function CosObjectStream(s::CosStream)
    n = get(s, CosName("N"))
    @assert n != CosNull
    first = get(s, CosName("First"))
    @assert first != CosNull
    cosStreamRemoveFilters(s)
    n_n = get(n)
    first_n = get(first)
    oids = Vector{Int}(n_n)
    oloc = Vector{Int}(n_n)
    read_object_info_from_stm(s, oids, oloc, n_n, first_n)
    new(s, n_n, first_n,oids, oloc)
  end
end

show(io::IO, os::CosObjectStream) = show(io, os.stm)

get(os::CosObjectStream, name::CosName) = get(os.stm, name)

get(os::CosIndirectObject{CosObjectStream}, name::CosName) = get(os.obj,name)

set!(os::CosObjectStream, name::CosName, obj::CosObject)=
    set!(os.stm, name, obj)

set!(os::CosIndirectObject{CosObjectStream}, name::CosName, obj::CosObject)=
    set!(os.obj,name,obj)

get(os::CosObjectStream) = get(os.stm)

@compat mutable struct CosXRefStream<: CosObject
  stm::CosStream
  isDecoded::Bool
  function CosXRefStream(s::CosStream,isDecoded::Bool=false)
    new(s,isDecoded)
  end
end

get(os::CosXRefStream, name::CosName) = get(os.stm, name)

get(os::CosIndirectObject{CosXRefStream}, name::CosName) = get(os.obj,name)

set!(os::CosXRefStream, name::CosName, obj::CosObject)=
    set!(os.stm, name, obj)

set!(os::CosIndirectObject{CosXRefStream}, name::CosName, obj::CosObject)=
    set!(os.obj,name,obj)

get(os::CosXRefStream) = get(os.stm)
