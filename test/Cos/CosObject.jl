using Test
using PDFIO.Cos: CosNullType, CosIndirectObject, CosObjectStream, CosComment

# CosString
using PDFIO.Cos: CosXString, CosLiteralString

# All CosObject
# julia> println.("  ", subtypes(CosObject));
#   CosArray
#   CosBoolean
#   CosDict
#   CosIndirectObjectRef
#   CosName
#   CosNumeric
#   CosStream
#   CosString
#   PDFIO.Cos.CosComment
#   PDFIO.Cos.CosIndirectObject
#   PDFIO.Cos.CosNullType
#   PDFIO.Cos.CosObjectStream

@testset "CosObject" begin

begin
    # simple CosObject val type
    SIMPLE_COS_VT = Union{Bool, Float32, Int, Symbol, String}
    # composite CosObject val type
    COMPOSITE_COS_VT = Union{
        Tuple{Int, Int},
        Vector{UInt8}, 
        Vector{CosObject},
        Dict{CosName,CosObject}
    }
    # all CosObject val type
    COS_VAL_TYPES = Union{SIMPLE_COS_VT, COMPOSITE_COS_VT}

    function test_get_val(T::Type{<:CosObject}, val::SIMPLE_COS_VT)
        # get(o::CosObject) = o.val
        @test T(val) |> get == val
    end
    test_get_val(T::Type{<:CosName}, str::String) =
        @test T(str) |> get == Symbol("CosName_",str)
    # get(o::CosIndirectObjectRef) -> (objnum, gennum)
    test_get_val(T::Type{CosIndirectObjectRef}, tup::Tuple) =
        T(tup...) |> get == tup
    function test_get_val(T, vec::Vector{<:SIMPLE_COS_VT})
        for val in vec
            test_get_val(T, val)
        end
    end
end

    @testset "CosBoolean" begin
        # val::Bool
        # test_get_val(CosBoolean, [true, false])
        @test CosTrue.val  == true  # CosBoolean(true)
        @test CosFalse.val == false # CosBoolean(false)
    end # end CosBoolean test

    @testset "CosNumeric" begin
        # val::Float32
        # test_get_val(CosFloat, rand(Float32, 10))
        _float32 = rand(Float32)
        @test CosFloat(_float32) |> get == _float32

        # CosInt
        #   val::Int
        # test_get_val(CosInt, rand(Int64, 10))
        _int64 = rand(Int64)
        @test CosInt(_int64) |> get == _int64
    end # end CosNumeric test

    @testset "CosIndirectObject" begin
        # num::Int, gen::Int, obj::CosObject
        _obj_tup = (num=0, gen=1, obj=CosInt(0))
        _ind_obj = CosIndirectObject(_obj_tup...)
        @test _ind_obj.num == _obj_tup.num
        @test _ind_obj.gen == _obj_tup.gen
        @test _ind_obj.obj == _obj_tup.obj

        # get(o::CosIndirectObject) = get(o.obj)
        @test _ind_obj |> get == _obj_tup.obj |> get
    end # end CosIndirectObject test

    @testset "CosIndirectObjectRef" begin
        # val::Tuple{Int, Int}
        # CosIndirectObjectRef(num::Int, gen::Int)=new((num, gen))
        _tup_int64 = rand(Int, 2) |> Tuple
        @test CosIndirectObjectRef(_tup_int64...) |> get == _tup_int64

        # CosIndirectObjectRef(obj::CosIndirectObject) =
        #   CosIndirectObjectRef(obj.num, obj.gen)
        _obj_tup = (num=0, gen=1, obj=CosInt(0))
        _ind_obj = CosIndirectObject(_obj_tup...)
        _ind_obj_ref = CosIndirectObjectRef(_ind_obj)
        @test _ind_obj_ref |> get == (_ind_obj.num, _ind_obj.gen)
    end # end CosIndirectObjectRef test

    @testset "CosName" begin
        # val::Symbol
        # CosName(str::AbstractString) = new(Symbol("CosName_",str))
        cosname(s) = Symbol("CosName_", s)

        # test_get_val(CosName, ["rand_symbol", "*", "c++"])
        _str = "rand_symbol"
        @test CosName(_str) |> get == cosname(_str)
    end # end CosName test

    @testset "@cn_str" begin
        # @cn_str(str) -> CosName
        @test cn"Name" |> get == CosName("Name") |> get
    end # end @cn_str test

    @testset "CosString" begin
        # get(o::T) where {T <: CosString} = copy(o.val)

        @testset "CosXString" begin
            # val::Vector{UInt8}
            # CosXString(arr::Vector{UInt8})=new(arr)

        end # end CosXString test
        @testset "CosLiteralString" begin
            # val::Vector{UInt8}
            # CosLiteralString(arr::Vector{UInt8}) = new(arr)

        end # end CosLiteralString test
    end # end CosString test

    @testset "CosArray" begin
        # val::Vector{CosObject}
        # CosArray(arr::Vector{CosObject}) = new(arr)
        # CosArray() = new(Vector{CosObject}())

        # get(o::CosArray, isNative=false) = isNative ? map(get, o.val) : o.val

        # get(o::CosIndirectObject{CosArray}, isNative=false) = get(o.obj, isNative)

        # length(o::CosArray) = length(o.val)
        # length(o::ID{CosArray}) = length(o.obj)

        # Base.getindex(o::CosArray, i::Int) = o.val[i]
        # Base.getindex(o::ID{CosArray}, i::Int) = getindex(o.obj, i)

    end # end CosArray test

    @testset "CosDict" begin
        # val::Dict{CosName, CosObject}
        # CosDict()=new(Dict{CosName, CosObject}())

    end # end CosDict test

    @testset "CosStream" begin
        # extent::CosDict
        # isInternal::Bool
        # CosStream(d::CosDict, isInternal::Bool=true) = new(d, isInternal)

    end # end CosStream test

    # ["$n::$t" for (n, t)  in (zip(fieldnames(CosObjectStream), fieldtypes(CosObjectStream)) |> collect)] |> a->join(a, ", ")
    @testset "CosObjectStream" begin
        # (stm::CosStream, n::Int64, first::Int64, oids::Array{Int64,1}, oloc::Array{Int64,1}, populated::Bool)

    end # end CosObjectStream test

    @testset "CosXRefStream" begin
        # stm::CosStream, isDecoded::Bool
        "Not imple"
    end # end CosXRefStream test

    @testset "CosComment" begin
        # val::String
        # CosComment(barr::Vector{UInt8}) = CosComment(String(Char.(barr)))

        # show(io::IO, os::CosComment) = print(io, '%', os.val)

    end # end CosComment test
end # end CosObject test
