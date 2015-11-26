require 'stringio'
require 'active_support/core_ext/big_decimal'

module Landlord
  class SchemaDumper < ActiveRecord::SchemaDumper

    private

      def header(stream)
        define_params = @version ? "version: #{@version}" : ""

        if stream.respond_to?(:external_encoding) && stream.external_encoding
          stream.puts "# encoding: #{stream.external_encoding.name}"
        end

        stream.puts <<HEADER
require 'landlord/schema'

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

Landlord::Schema.define(#{define_params}) do

HEADER
      end
  end
end
