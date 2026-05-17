require "open3"
require "hiera/backend/eyaml/encryptor"
require "hiera/backend/eyaml/utils"
require "hiera/backend/eyaml/options"
require "hiera/backend/eyaml/encryptors/age/version"

class Hiera
  module Backend
    module Eyaml
      module Encryptors
        class Age < Encryptor
          VERSION = Hiera::Backend::Eyaml::Encryptors::AgeVersion::VERSION
          self.tag = "AGE"

          self.options = {
            age_binary_path: {
              desc: "Full path to the age executable",
              type: :string,
              default: "age"
            },
            identity_file: {
              desc: "Path to age identity file for decryption",
              type: :string
            },
            recipients: {
              desc: "List of recipients (comma separated)",
              type: :string
            },
            recipients_file: {
              desc: "File containing a list of recipients (one on each line)",
              type: :string
            }
          }

          def self.encrypt(plaintext)
            recipients = determine_recipients
            debug("Recipients are #{recipients}")

            if recipients.empty?
              raise RecoverableError,
                    "No recipients provided, don't know who to encrypt to"
            end

            recipient_args =
              recipients.flat_map { |recipient| ["-r", recipient] }

            stdout, stderr, status =
              Open3.capture3(
                option(:age_binary_path),
                "--encrypt",
                *recipient_args,
                stdin_data: plaintext,
                binmode: true
              )
            unless status.success?
              raise RecoverableError, "age encrypt failed: #{stderr.strip}"
            end

            stdout
          end

          def self.decrypt(ciphertext)
            identity_file = option(:identity_file)
            debug("age identity file is #{identity_file}")

            if identity_file.nil? || identity_file.empty?
              raise ArgumentError,
                    "No age identity file configured, check age_identity_file configuration value is correct"
            elsif !File.exist?(identity_file)
              raise ArgumentError,
                    "Configured age identity file #{identity_file} doesn't exist, check age_identity_file configuration value is correct"
            end

            stdout, stderr, status =
              Open3.capture3(
                option(:age_binary_path),
                "--decrypt",
                "--identity",
                identity_file,
                stdin_data: ciphertext,
                binmode: true
              )

            unless status.success?
              warn(
                "Fatal: Failed to decrypt ciphertext (check settings and that you are a recipient)"
              )
              raise StandardError, "age decrypt failed: #{stderr.strip}"
            end

            stdout
          end

          def self.create_keys
            warn "The age encryptor does not support creation of keys, use the age command line tools instead"
          end

          class << self
            private

            def determine_recipients
              recipient_option = option :recipients

              unless recipient_option.nil?
                debug("Using --recipients option")
                return recipient_option.split(",").map(&:strip)
              end

              recipients_file_option = option :recipients_file
              return [] if recipients_file_option.nil?

              debug("Using --recipients-file option")
              File
                .readlines(recipients_file_option)
                .map do |line|
                  line.strip unless line.start_with?("#") || line.strip.empty?
                end
                .compact
            end
          end
        end
      end
    end
  end
end
