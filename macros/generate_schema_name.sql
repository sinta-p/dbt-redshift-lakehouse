{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if node.config.materialized == 's3tables_iceberg' -%}
        {# External namespaces already exist; use their exact configured name.
           These outputs are shared, so use distinct schemas/aliases for dev and prod. #}
        {%- if custom_schema_name is none or not (custom_schema_name | trim) -%}
            {{ exceptions.raise_compiler_error('s3tables_iceberg requires an explicit schema.') }}
        {%- endif -%}
        {{ custom_schema_name | trim }}
    {%- elif custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
