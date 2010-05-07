module Globalize
  module ActiveRecord
    module Migration
      def create_translation_table!(fields)
        translated_attribute_names.each do |f|
          raise MigrationMissingTranslatedField, "Missing translated field #{f}" unless fields[f]
        end

        fields.each do |name, type|
          if translated_attribute_names.include?(name) && ![:string, :text].include?(type)
            raise BadMigrationFieldType, "Bad field type for #{name}, should be :string or :text"
          end
        end

        connection.create_table(translation_table_name) do |t|
          if translation_table_foreign_key
            t.integer translation_table_foreign_key
          else
            t.references table_name.sub(/^#{table_name_prefix}/, "").singularize, :foreign_key => translation_class.foreign_key
          end
          t.string :locale
          fields.each do |name, type|
            t.column name, type
          end
          t.timestamps
        end

        connection.add_index(
          translation_table_name,
          translation_table_foreign_key || "#{table_name.sub(/^#{table_name_prefix}/, "").singularize}_id",
          :name => translation_index_name
        )
      end

      def translation_index_name
        require 'digest/sha1'
        # FIXME what's the max size of an index name?
        index_name = "index_#{translation_table_name}_on_#{table_name.singularize}_id"
        index_name.size < 50 ? index_name : "index_#{Digest::SHA1.hexdigest(index_name)}"
      end

      def drop_translation_table!
        connection.remove_index(translation_table_name, :name => translation_index_name) rescue nil
        connection.drop_table(translation_table_name)
      end
    end
  end
end
