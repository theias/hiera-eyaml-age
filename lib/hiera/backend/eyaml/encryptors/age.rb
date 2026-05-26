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
              desc: "Full path to the age executable (use an absolute path in production to avoid PATH-based substitution)",
              type: :string,
              default: "age"
            },
            identity_file: {
              desc: "Path to age identity file for decryption",
              type: :string
            },
            identity_env_var: {
              desc: "Name of environment variable containing age identity for decryption",
              type: :string
            },
            recipients: {
              desc: "List of recipients (comma separated)",
              type: :string
            },
            recipients_file: {
              desc: "File containing a list of recipients (one on each line)",
              type: :string
            },
            recipients_env_var: {
              desc: "Name of environment variable containing age recipients (comma separated)",
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
              warn("age encrypt failed (run with --trace for details, including errors from age which may be sensitive)")
              debug("age encrypt stderr: #{stderr.strip}")
              raise RecoverableError, "age encrypt failed"
            end

            stdout
          end

          def self.decrypt(ciphertext)
            env_var = option(:identity_env_var)

            if env_var
              raise ArgumentError, "env #{env_var} is not set" unless ENV[env_var]

              # Pass the identity via a pipe rather than a temp file so the key
              # material never touches disk. age's --identity accepts /dev/fd/N.
              # Ruby 2.0+ opens FDs with O_CLOEXEC by default, so we must
              # explicitly preserve the read end across the exec boundary.
              r_fd, w_fd = IO.pipe
              w_fd.write(ENV[env_var])
              w_fd.close
              identity_arg = "/dev/fd/#{r_fd.fileno}"
              extra_opts = { r_fd.fileno => r_fd }
            else
              identity_file = option(:identity_file)
              debug("age identity file is #{identity_file}")

              if identity_file.nil? || identity_file.empty?
                raise ArgumentError,
                      "No age identity file configured, check age_identity_file configuration value is correct"
              end

              identity_arg = identity_file
              extra_opts = {}
            end

            stdout, stderr, status =
              Open3.capture3(
                option(:age_binary_path),
                "--decrypt",
                "--identity",
                identity_arg,
                stdin_data: ciphertext,
                binmode: true,
                **extra_opts
              )

            r_fd&.close

            unless status.success?
              warn("age decrypt failed (run with --trace for details, including errors from age which may be sensitive)")
              debug("age decrypt stderr: #{stderr.strip}")
              raise StandardError, "age decrypt failed"
            end

            stdout
          end

          def self.create_keys
            warn "The age encryptor does not support creation of keys, use the age command line tools instead"
          end

          class << self
            private

            def determine_recipients
              env_var = option(:recipients_env_var)
              if env_var
                raise ArgumentError, "env #{env_var} is not set" unless ENV[env_var]

                debug("Using --recipients-env-var option")
                return ENV[env_var].split(",").map(&:strip)
              end

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
