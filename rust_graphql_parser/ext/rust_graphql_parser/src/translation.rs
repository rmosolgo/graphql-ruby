use std::any::type_name;

use graphql_parser::query::{
    Definition, Document, Field, FragmentDefinition, FragmentSpread, InlineFragment, Mutation,
    OperationDefinition, Query, Selection, SelectionSet, Subscription, TypeCondition,
    VariableDefinition,
};
use graphql_parser::schema::{Directive, Type, Value};
use graphql_parser::Pos;
use rb_sys::{VALUE, rb_intern, rb_hash_new, rb_id2sym, rb_hash_aset, rb_hash_bulk_insert, rb_ary_new_capa, rb_ary_push};


macro_rules! static_cstring {
    ($string:expr) => {{
        concat!($string, "\0").as_ptr() as *const std::os::raw::c_char
    }};
}

pub unsafe fn translate_document<'a>(doc: &'a Document<'a, &'a str>) -> VALUE {
    let definitions = rb_sys::rb_ary_new();
    for x in doc.definitions.iter() {
        rb_sys::rb_ary_push(definitions, translate_definition(x));
    }
    let kwargs = rb_hash_new();
    rb_sys::rb_hash_aset(
        kwargs, rb_sys::rb_id2sym(rb_intern(static_cstring!("definitions"))), definitions);
    return build_instance(*classes::DOCUMENT, kwargs);
}

unsafe fn translate_definition<'a>(definition: &'a Definition<'a, &'a str>) -> VALUE {
    return match definition {
        Definition::Operation(operation) => translate_operation_definition(operation),
        Definition::Fragment(fragment) => translate_fragment_definition(fragment),
    };
}

unsafe fn translate_operation_definition<'a>(operation_definition: &'a OperationDefinition<'a, &'a str>) -> VALUE {
    if let OperationDefinition::SelectionSet(selection_set) = &operation_definition {
        return translate_top_level_selection_set(selection_set);
    }
    return match operation_definition {
        OperationDefinition::Query(query) => translate_query(query),
        OperationDefinition::SelectionSet(selection_set) => translate_selection_set(selection_set),
        OperationDefinition::Mutation(mutation) => translate_mutation(mutation),
        OperationDefinition::Subscription(subscription) => translate_subscription(subscription),
    };
}

unsafe fn translate_top_level_selection_set<'a>(selection_set: &SelectionSet<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::OPERATION_TYPE, ruby_str("query"),
        *symbols::SELECTIONS, translate_selection_set(selection_set),
    ]);
    return build_instance(*classes::OPERATION_DEFINITION, kwargs);
}

unsafe fn translate_query<'a>(query: &Query<'a, &'a str>) -> VALUE {
    translate_operation(
        "query",
        query.name,
        &query.selection_set,
        &query.variable_definitions,
        &query.directives,
    )
}

unsafe fn translate_mutation<'a>(mutation: &Mutation<'a, &'a str>) -> VALUE {
    translate_operation(
        "mutation",
        mutation.name,
        &mutation.selection_set,
        &mutation.variable_definitions,
        &mutation.directives,
    )
}

unsafe fn translate_subscription<'a>(subscription: &Subscription<'a, &'a str>) -> VALUE {
    translate_operation(
        "subscription",
        subscription.name,
        &subscription.selection_set,
        &subscription.variable_definitions,
        &subscription.directives,
    )
}

unsafe fn translate_operation<'a>(
    operation_type: &str,
    operation_name: Option<&'a str>,
    selection_set: &SelectionSet<'a, &'a str>,
    definitions: &Vec<VariableDefinition<'a, &'a str>>,
    directives: &Vec<Directive<'a, &'a str>>
) -> VALUE {
    let kwargs = rb_hash_new();
    rb_hash_aset(kwargs, *symbols::OPERATION_TYPE, ruby_str(operation_type));
    if let Some(name) = &operation_name {
        rb_hash_aset(kwargs, *symbols::NAME, ruby_str(name));
    }
    rb_hash_aset(kwargs, *symbols::SELECTIONS,
        translate_selection_set(selection_set));
    rb_hash_aset(kwargs, *symbols::VARIABLES, 
        translate_variable_definitions(definitions));
    rb_hash_aset(kwargs, *symbols::DIRECTIVES, 
        translate_directives(directives));    
    return build_instance(*classes::OPERATION_DEFINITION, kwargs);
}

unsafe fn translate_variable_definitions<'a>(definitions: &Vec<VariableDefinition<'a, &'a str>>) -> VALUE {
    let result:VALUE = rb_ary_new_capa(definitions.len() as _);
    for x in definitions {
        let kwargs = build_hash(&[
            *symbols::NAME, ruby_str(&x.name),
            *symbols::TYPE, translate_type(&x.var_type),
            *symbols::DEFAULT_VALUE, x.default_value.as_ref().map_or(rb_sys::Qnil as _,
                 |x| {translate_value(&x)}
            )
        ]);
        rb_ary_push(result, build_instance(*classes::VARIABLE_DEFINITION, kwargs));
    }
    return result;
}

unsafe fn translate_fragment_definition<'a>(fragment_definition: &FragmentDefinition<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::NAME, ruby_str(&fragment_definition.name),
        *symbols::TYPE, translate_type_condition(&fragment_definition.type_condition),
        *symbols::SELECTIONS, translate_selection_set(&fragment_definition.selection_set),
    ]);
    return build_instance(*classes::FRAGMENT_DEFINITION, kwargs);
}

unsafe fn translate_type_condition<'a>(type_condition: &TypeCondition<'a, &'a str>) -> VALUE {
    let TypeCondition::On(type_name) = type_condition;
    let kwargs = build_hash(&[*symbols::NAME, ruby_str(type_name)]);
    return build_instance(*classes::TYPE_NAME, kwargs);
}

unsafe fn translate_selection_set<'a>(selection_set: &SelectionSet<'a, &'a str>) -> VALUE {
    let result: VALUE = rb_ary_new_capa(selection_set.items.len() as _);
    for x in selection_set.items.iter() {
        rb_ary_push(result, translate_selection(x));
    }
    return result;
    // let hash = RHash::new();
    // hash.aset(Symbol::new("node_type"), Symbol::new("selection_set"))
    //     .unwrap();

    // let span = RArray::new();
    // span.push(translate_position(&selection_set.span.0))
    //     .unwrap();
    // span.push(translate_position(&selection_set.span.1))
    //     .unwrap();
    // hash.aset(Symbol::new("span"), span).unwrap();

    // let items = RArray::new();
    // for x in selection_set.items.iter() {
    //     items.push(translate_selection(x)).unwrap();
    // }
    // hash.aset(Symbol::new("items"), items).unwrap();

    // return hash;
}

unsafe fn translate_selection<'a>(selection: &Selection<'a, &'a str>) -> VALUE {
    return match selection {
        Selection::Field(field) => translate_field(field),
        Selection::FragmentSpread(fragment_spread) => translate_fragment_spread(fragment_spread),
        Selection::InlineFragment(inline_fragment) => translate_inline_fragment(inline_fragment),
    };
}

unsafe fn translate_field<'a>(field: &Field<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::NAME, ruby_str(&field.name),
        *symbols::ARGUMENTS, translate_arguments(&field.arguments),
        *symbols::SELECTIONS, translate_selection_set(&field.selection_set),
    ]);
    if let Some(alias) = &field.alias {
        rb_hash_aset(kwargs, *symbols::FIELD_ALIAS, ruby_str(&alias));
    }
    rb_hash_aset(kwargs, *symbols::DIRECTIVES, translate_directives(&field.directives));

    return build_instance(*classes::FIELD, kwargs);
}

unsafe fn translate_arguments<'a>(arguments: &Vec<(&'a str, Value<'a, &'a str>)>) -> VALUE {
    let result: VALUE = rb_ary_new_capa(arguments.len() as _);
    for (arg_name, arg_value) in arguments {
        rb_ary_push(result, translate_argument(arg_name, arg_value));
    }
    return result;
}

unsafe fn translate_argument<'a>(name: &str, value: &Value<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::NAME, ruby_str(name),
        *symbols::VALUE, translate_value(value),
    ]);
    return build_instance(*classes::ARGUMENT, kwargs);
}

unsafe fn translate_value<'a>(value: &Value<'a, &'a str>) -> VALUE {
    return match value {
        Value::Variable(variable) => {
            let kwargs = build_hash(&[
                *symbols::NAME, ruby_str(variable),
            ]);
            build_instance(*classes::VARIABLE_IDENTIFIER, kwargs)
        }
        Value::Int(number) => {
            rb_sys::rb_int2inum(number.as_i64().unwrap() as _)
        }
        Value::Float(number) => {
            rb_sys::rb_float_new(*number)
        }
        Value::String(str) => {
            ruby_str(str)
        }
        Value::Boolean(true) => { rb_sys::Qtrue as _ },
        Value::Boolean(false) => { rb_sys::Qfalse as _ },
        Value::Null => { 
            build_instance(
                *classes::NULL_VALUE,
                build_hash(&[*symbols::NAME, ruby_str("null")])
            )
        },
        Value::Enum(enum_name) => {
            build_instance(
                *classes::ENUM,
                build_hash(&[*symbols::NAME, ruby_str(&enum_name)])
            )
        }
        Value::List(vals) => {
            let result: VALUE = rb_ary_new_capa(vals.len() as _);
            for v in vals.iter() {
                rb_ary_push(result, translate_value(v));
            }
            result
        }
        Value::Object(obj) => {
            let arguments: VALUE = rb_ary_new_capa(obj.len() as _);
            for (name, val) in obj.iter() {
                rb_ary_push(arguments, translate_argument(name, val));
            }
            let kwargs = build_hash(&[
                *symbols::ARGUMENTS, arguments
            ]);
            build_instance(*classes::INPUT_OBJECT, kwargs)
        }
    };
}

unsafe fn translate_directives<'a>(directives: &Vec<Directive<'a, &'a str>>) -> VALUE {
    let result = rb_ary_new_capa(directives.len() as _);
    for directive in directives.iter() {
        rb_ary_push(result, translate_directive(directive));
    }
    return result;
}

unsafe fn translate_directive<'a>(directive: &Directive<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::NAME, ruby_str(&directive.name),
        *symbols::ARGUMENTS, translate_arguments(&directive.arguments),
    ]);
    return build_instance(*classes::DIRECTIVE, kwargs);
}

unsafe fn translate_fragment_spread<'a>(fragment_spread: &FragmentSpread<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::NAME, ruby_str(fragment_spread.fragment_name),
    ]);
    return build_instance(*classes::FRAGMENT_SPREAD, kwargs);
}

unsafe fn translate_inline_fragment<'a>(inline_fragment: &InlineFragment<'a, &'a str>) -> VALUE {
    let kwargs = build_hash(&[
        *symbols::SELECTIONS, translate_selection_set(&inline_fragment.selection_set),
        *symbols::DIRECTIVES, translate_directives(&inline_fragment.directives),
    ]);
    if let Some(TypeCondition::On(on_type)) = &inline_fragment.type_condition {
        rb_hash_aset(
            kwargs,
            *symbols::TYPE,
            build_instance(
                *classes::TYPE_NAME,
                build_hash(&[*symbols::NAME, ruby_str(on_type)])
            )
        );
    }
    return build_instance(*classes::INLINE_FRAGMENT, kwargs);
}

unsafe fn translate_type<'a>(type_def: &Type<'a, &'a str>) -> VALUE {
    return match type_def {
        Type::NamedType(type_name) => {
            let kwargs = build_hash(&[*symbols::NAME, ruby_str(&type_name)]);
            build_instance(*classes::TYPE_NAME, kwargs)
        }
        Type::ListType(inner_type) => {
            let kwargs = build_hash(&[
                *symbols::OF_TYPE, translate_type(inner_type)
            ]);
            build_instance(*classes::LIST_TYPE, kwargs)
        }
        Type::NonNullType(inner_type) => {
            let kwargs = build_hash(&[
                *symbols::OF_TYPE, translate_type(inner_type)
            ]);
            build_instance(*classes::NON_NULL_TYPE, kwargs)
        }
    };
}

mod symbols {
    use rb_sys::{VALUE, rb_intern, rb_hash_new, rb_id2sym, rb_hash_aset, rb_hash_bulk_insert};
    use once_cell::sync::Lazy;
    pub static NAME: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("name"))
    });
    pub static TYPE: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("type"))
    });
    pub static SELECTIONS: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("selections"))
    });
    pub static OPERATION_TYPE: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("operation_type"))
    });
    pub static VARIABLES: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("variables"))
    });
    pub static OF_TYPE: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("of_type"))
    });
    pub static FIELD_ALIAS: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("field_alias"))
    });
    pub static ARGUMENTS: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("arguments"))
    });
    pub static VALUE: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("value"))
    });
    pub static DIRECTIVES: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("directives"))
    });
    pub static DEFAULT_VALUE: Lazy<VALUE> = Lazy::new(|| unsafe {
        rb_id2sym(rb_intern!("default_value"))
    });
}

mod classes {
    use rb_sys::{VALUE, rb_intern};
    use once_cell::sync::Lazy;
    pub static DOCUMENT: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("Document"))
    });
    pub static FIELD: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("Field"))
    });
    pub static FRAGMENT_DEFINITION: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("FragmentDefinition"))
    });
    pub static TYPE_NAME: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("TypeName"))
    });
    pub static OPERATION_DEFINITION: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("OperationDefinition"))
    });
    pub static VARIABLE_DEFINITION: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("VariableDefinition"))
    });
    pub static LIST_TYPE: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("ListType"))
    });
    pub static NON_NULL_TYPE: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("NonNullType"))
    });
    pub static ARGUMENT: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("Argument"))
    });
    pub static VARIABLE_IDENTIFIER: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("VariableIdentifier"))
    });
    pub static NULL_VALUE: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("NullValue"))
    });
    pub static ENUM: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("Enum"))
    });
    pub static INLINE_FRAGMENT: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("InlineFragment"))
    });
    pub static INPUT_OBJECT: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("InputObject"))
    });
    pub static DIRECTIVE: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("Directive"))
    });
    pub static FRAGMENT_SPREAD: Lazy<VALUE> = Lazy::new(|| unsafe {
        resolve(static_cstring!("FragmentSpread"))
    });

    unsafe fn resolve(class_name: *const std::os::raw::c_char) -> VALUE {
        let cGraphQL = rb_sys::rb_const_get(
            rb_sys::rb_cObject, 
            rb_intern!("GraphQL"));
        let cLanguage = rb_sys::rb_const_get(
            cGraphQL, 
            rb_intern!("Language"));
        let cNodes = rb_sys::rb_const_get(
            cLanguage, 
            rb_intern!("Nodes"));
        
        return rb_sys::rb_const_get(
            cNodes,
            rb_intern(class_name));
    }    
}

unsafe fn unimplemented() -> VALUE {
    return build_hash(&[rb_id2sym(rb_intern(static_cstring!("unimplemented"))), rb_sys::Qtrue as _])
}

unsafe fn build_hash(arr: &[VALUE]) -> VALUE {
    let result = rb_hash_new();
    rb_hash_bulk_insert(arr.len() as _, arr.as_ptr(), result);
    return result;
}

unsafe fn build_instance(class: VALUE, kwargs: VALUE) -> VALUE {
    rb_sys::rb_class_new_instance_kw(1, &kwargs, class, 1)
}

unsafe fn ruby_str(rust_str: &str) -> VALUE {
    rb_sys::rb_str_new(rust_str.as_ptr() as _,rust_str.len() as _)
}

macro_rules! build_node {
    ($class:expr, $($args:expr),*) => {
        rb_sys::rb_funcall(
            $class,
            rb_intern!("from_a"),
            count_args!( $($args),* ),
            $($args),*
        );
    };
}

macro_rules! count_args {
    () => { 0 };
    ($_arg:expr $(, $args:expr)*) => { 1 + count_args!($($args),*) };
}
