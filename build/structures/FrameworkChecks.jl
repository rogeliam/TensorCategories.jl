#=----------------------------------------------------------
    Generic checks for categories 
----------------------------------------------------------=#

is_fusion(C::Category) = is_multifusion(C) && int_dim(End(one(C))) == 1

is_multifusion(C::Category) = is_multitensor(C) && is_semisimple(C) && is_finite(C)

is_tensor(C::Category) = is_multitensor(C) && int_dim(End(one(C))) == 1

is_multitensor(C::Category) = is_multiring(C) && is_rigid(C)

is_ring(C::Category) = is_multiring(C) && int_dim(End(one(C))) == 1

is_multiring(C::Category) = is_abelian(C) && is_linear(C) && is_monoidal(C)

function is_monoidal(C::Category) 
    T = object_type(C)
    hasmethod(one, Tuple{typeof(C)}) &&
    hasmethod(tensor_product, Tuple{T,T}) 
end

function is_abelian(C::Category) 
    if is_additive(C) && is_linear(C)
        T = morphism_type(C)
        return hasmethod(kernel, Tuple{T}) && hasmethod(cokernel, Tuple{T})
    end
    return false
end

function is_additive(C::Category) 
    T = object_type(C)
    hasmethod(direct_sum, Tuple{T,T}) && hasmethod(zero, Tuple{typeof(C)})
end


function is_linear(C::Category) 
    hasmethod(base_ring, Tuple{typeof(C)})
end

is_semisimple(C::Category) = is_multitensor(C)

function is_modular(C::Category) 
     try
        return det(smatrix(C)) != 0 
    catch 
        return false 
    end
end

function is_spherical(C::Category)
    @assert is_multifusion(C) "Generic checking only available for multifusion categories"

    obj_type = typeof(one(C))
    if  !hasmethod(spherical, Tuple{obj_type})
        return false
    end
    try 
        for x ∈ simples(C)
            spherical(x)
        end
        return true
    catch
        return false
    end
end

function is_rigid(C::Category)
    T = object_type(C)
    is_monoidal(C) && hasmethod(dual, Tuple{T}) && hasmethod(ev, Tuple{T}) && hasmethod(coev, Tuple{T})
end

function is_braided(C::Category)
    T = object_type(C)
    is_monoidal(C) && hasmethod(braiding, Tuple{T,T})
end

function is_krull_schmidt(C::Category)
    # TODO: Set up
    false
end


#=----------------------------------------------------------
    Helpers 
----------------------------------------------------------=#

function all_subtypes(T::Type)
    sub_types = subtypes(T)
    
    is_abstract = isabstracttype.(sub_types)

    concrete_types = sub_types[true .⊻ (is_abstract)]
    abstract_types = sub_types[is_abstract]

    return [concrete_types; vcat(all_subtypes.(abstract_types))...]
end


function object_type(C::Category)
    object_types = all_subtypes(Object)

    for T ∈ object_types
        if hasfield(T, :parent)
            if typeof(C) <: fieldtype(T,:parent)
                return T
            end
        end
    end
end 

function morphism_type(C::Category)
    morphism_types = all_subtypes(Morphism)

    for T ∈ morphism_types
        if hasfield(T, :domain)
            if object_type(C) <: fieldtype(T,:domain)
                return T
            end
        end
    end
end 