#------------------------------------------------------------------------
#   Structs for categories
#------------------------------------------------------------------------

abstract type Category end

abstract type Object end

abstract type Morphism end


"""
    VectorSpaceObject{T}

An object in the category of finite dimensional vector spaces.
"""
abstract type VectorSpaceObject <: Object end

"""
    VectorSpaceMorphism{T}()

A morphism in the category of finite dimensional vector spaces.
"""
abstract type VectorSpaceMorphism <: Morphism end

abstract type HomSet end

abstract type HomSpace <: VectorSpaceObject end

domain(m::Morphism) = m.domain
codomain(m::Morphism) = m.codomain

"""
    parent(X::Object)

Return the parent category of the object X.
"""
parent(X::Object) = X.parent

"""
    base_ring(X::Object)

Return the base ring ```k``` of the ```k```-linear parent category of ```X```.
"""
base_ring(X::Object) = parent(X).base_ring

base_ring(X::Morphism) = parent(domain(X)).base_ring
"""
    base_ring(C::Category)

Return the base ring ```k```of the ```k```-linear category ```C```.
"""
base_ring(C::Category) = C.base_ring

base_group(C::Category) = C.base_group
base_group(X::Object) = parent(X).base_group

#---------------------------------------------------------
#   Direct Sums, Products, Coproducts
#---------------------------------------------------------

function ⊕(T::Tuple{S,Vector{R},Vector{R2}},X::S1) where {S <: Object,S1 <: Object, R <: Morphism, R2 <: Morphism}
    Z,ix,px = dsum(T[1],X)
    incl = vcat([ix[1] ∘ t for t in T[2]], ix[2:2])
    proj = vcat([t ∘ px[1] for t in T[3]], px[2:2])
    return Z, incl, proj
end

⊕(X::S1,T::Tuple{S,Vector{R}, Vector{R2}}) where {S <: Object,S1 <: Object, R <: Morphism, R2 <: Morphism} = ⊕(T,X)

function dsum(X::Object...)
    if length(X) == 0 return nothing end
    Z = X[1]
    for Y ∈ X[2:end]
        Z = dsum(Z,Y)
    end
    return Z
end

function dsum_morphisms(X::Object...)
    if length(X) == 1
        return X[1], [id(X[1]),id(X[1])]
    end
    Z,ix,px = dsum(X[1],X[2],true)
    for Y in X[3:end]
        Z,ix,px = ⊕((Z,ix,px),Y)
    end
    return Z,ix,px
end

function dsum(f::Morphism...)
    g = f[1]

    for h ∈ f[2:end]
        g = g ⊕ h
    end
    return g
end

function ×(T::Tuple{S,Vector{R}},X::S1) where {S <: Object,S1 <: Object, R <: Morphism}
    Z,px = product(T[1],X)
    m = vcat([t ∘ px[1] for t in T[2]], px[2])
    return Z, m
end

×(X::S1,T::Tuple{S,Vector{R}}) where {S <: Object,S1 <: Object, R <: Morphism} = ×(T,X)

function product(X::Object...)
    if length(X) == 0 return nothing end
    Z = X[1]
    for Y ∈ X[2:end]
        Z = product(Z,Y)
    end
    return Z
end

function product_morphisms(X::Object...)
    if length(X) == 1
        return X[1], [id(X[1])]
    end
    Z,px = product(X[1],X[2], true)
    for Y in X[3:end]
        Z,px = ×((Z,px),Y)
    end
    return Z,px
end

function ∐(T::Tuple{S,Vector{R}},X::S1) where {S <: Object,S1 <: Object, R <: Morphism}
    Z,px = coproduct(T[1],X)
    m = vcat([px[1] ∘ t for t in T[2]], px[2])
    return Z, m
end

∐(X::S1,T::Tuple{S,Vector{R}}) where {S <: Object,S1 <: Object, R <: Morphism} = ∐(T,X)

function coproduct(X::Object...)
    if length(X) == 0 return nothing end
    Z = X[1]
    for Y in X[2:end]
        Z = coproduct(Z,Y)
    end
    return Z
end

function coproduct_morphisms(X::Object...)
    if length(X) == 1
        return X[1], [id(X[1])]
    end
    Z,ix = coproduct(X[1],X[2])
    for Y in X[3:end]
        Z,ix = ∐((Z,ix),Y)
    end
    return Z,ix
end

"""
    ×(X::Object...)

Return the product Object and an array containing the projection morphisms.
"""
×(X::Object...) = product(X...)

"""
    ∐(X::Object...)

Return the coproduct Object and an array containing the injection morphisms.
"""
∐(X::Object...) = coproduct(X...)

"""
    ⊕(X::Object...)

Return the direct sum Object and arrays containing the injection and projection
morphisms.
"""

⊕(X::Object...) = dsum(X...)

⊕(X::Morphism...) = dsum(X...)

"""
    ⊗(X::Object...)

Return the tensor product object.
"""
⊗(X::Object...) = tensor_product(X...)

"""
    ^(X::Object, n::Integer)

Return the n-fold product object ```X^n```.
"""
^(X::Object,n::Integer) = n == 0 ? zero(parent(X)) : product([X for i in 1:n]...)

^(X::Morphism,n::Integer) = n == 0 ? zero_morphism(zero(parent(domain(X))), zero(parent(domain(X)))) : dsum([X for i in 1:n]...)
"""
    ⊗(f::Morphism, g::Morphism)

Return the tensor product morphism of ```f```and ```g```.
"""
⊗(f::Morphism, g::Morphism) where {T} = tensor_product(f,g)


dsum(X::T) where T <: Union{Vector,Tuple} = dsum(X...)
product(X::T) where T <: Union{Vector,Tuple} = product(X...)
coproduct(X::T) where T <: Union{Vector,Tuple} = coproduct(X...)

product(X::Object,Y::Object) = dsum(X,Y)
coproduct(X::Object, Y::Object) = dsum(X,Y)
#---------------------------------------------------------
#   tensor_product
#---------------------------------------------------------

function tensor_product(X::Object...)
    if length(X) == 1 return X end

    Z = X[1]
    for Y ∈ X[2:end]
        Z = Z⊗Y
    end
    return Z
end

tensor_product(X::T) where T <: Union{Vector,Tuple} = tensor_product(X...)
#------------------------------------------------------
#   Abstract Methods
#------------------------------------------------------
isfusion(C::Category) = false
ismultifusion(C::Category) = isfusion(C)

istensor(C::Category) = isfusion(C)
ismultitensor(C::Category) = ismultifusion(C) || istensor(C)

ismonoidal(C::Category) = ismultitensor(C)

isabelian(C::Category) = ismultitensor(C)

isadditive(C::Category) = isabelian(C)

islinear(C::Category) = isabelian(C)

issemisimple(C::Category) = ismultitensor(C)

function image(f::Morphism)
    C,c = cokernel(f)
    return kernel(c)
end

∘(f::Morphism...) = compose(reverse(f)...)

-(f::Morphism, g::Morphism) = f + (-1)*g
-(f::Morphism) = (-1)*f

#-------------------------------------------------------
# Hom Spaces
#-------------------------------------------------------

dim(V::HomSpace) = length(basis(V))

End(X::Object) = Hom(X,X)


#-------------------------------------------------------
# Duals
#-------------------------------------------------------

left_dual(X::Object) = dual(X)
right_dual(X::Object) = dual(X)

dual(f::Morphism) = left_dual(f)

function left_dual(f::Morphism)
    X = domain(f)
    Y = codomain(f)
    a = ev(Y)⊗id(dual(X))
    b = id(dual(Y)⊗f)⊗id(dual(X))
    c = inv(associator(dual(Y),X,dual(X)))
    d = id(dual(Y)⊗coev(X))
    (a)∘(b)∘(c)∘(d)
end

tr(f::Morphism) = left_trace(f)

function left_trace(f::Morphism)
    V = domain(f)
    W = codomain(f)
    C = parent(V)
    if V == zero(C) || W == zero(C) return zero_morphism(one(C),one(C)) end

    if V == W
        return ev(left_dual(V)) ∘ ((spherical(V)∘f) ⊗ id(left_dual(V))) ∘ coev(V)
    end
    return ev(left_dual(V)) ∘ (f ⊗ id(left_dual(V))) ∘ coev(V)
end

function right_trace(f::Morphism)
    V = domain(f)
    W = codomain(f)
    dV = right_dual(V)
    _,i = isisomorphic(left_dual(dV),V)
    _,j = isisomorphic(right_dual(V), left_dual(right_dual(dV)))
    return (ev(right_dual(dV))) ∘ (j⊗(f∘i)) ∘ coev(right_dual(V))
end

#-------------------------------------------------------
# Spherical structure
#-------------------------------------------------------

function drinfeld_morphism(X::Object)
     (ev(X)⊗id(dual(dual(X)))) ∘ (braiding(X,dual(X))⊗id(dual(dual(X)))) ∘ (id(X)⊗coev(dual(X)))
 end

dim(X::Object) = base_ring(X)(tr(spherical(X)))

dim(C::Category) = sum(dim(s)^2 for s ∈ simples(C))
#-------------------------------------------------------
# S-Matrix
#-------------------------------------------------------

function smatrix(C::Category, simples = simples(C))
    @assert issemisimple(C) "Category has to be semisimple"
    F = base_ring(C)
    m = [tr(braiding(s,t)∘braiding(t,s)) for s ∈ simples, t ∈ simples]
    try
        return matrix(F,[F(n) for n ∈ m])
    catch
    end
    return matrix(F,m)
end

#-------------------------------------------------------
# decomposition morphism
#-------------------------------------------------------

function decompose(X::Object)
    C = parent(X)
    @assert issemisimple(C) "Category not semisimple"
    S = simples(C)
    dimensions = [dim(Hom(X,s)) for s ∈ S]
    return [(s,d) for (s,d) ∈ zip(S,dimensions) if d > 0]
end

function decompose_morphism(X::Object)
    C = parent(X)
    @assert issemisimple(C) "Semisimplicity required"

    S = simples(C)

    proj = [basis(Hom(X,s)) for s ∈ S]
    dims = [length(p) for p ∈ proj]

    Z = dsum([s^d for (s,d) ∈ zip(S,dims)])
    incl = [basis(Hom(s,Z)) for s ∈ S]

    f = zero_morphism(X,Z)

    for (pk,ik) ∈ zip(proj, incl)
        for (p,i) ∈ zip(pk,ik)
            g = i∘p
            f = f + g
        end
    end
    return f
end




#-------------------------------------------------------
# Semisimple: Subobjects
#-------------------------------------------------------

function unique_simples(simples::Vector{<:Object})
    unique_simples = simples[1:1]
    for s ∈ simples[2:end]
        if sum([dim(Hom(s,u)) for u ∈ unique_simples]) == 0
            unique_simples = [unique_simples; s]
        end
    end
    return unique_simples
end
