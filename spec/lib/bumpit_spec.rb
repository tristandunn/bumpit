# frozen_string_literal: true

RSpec.describe Bumpit do
  it "has a version number" do
    expect(Bumpit::VERSION).not_to be_nil
  end

  describe "#call" do
    subject(:call) { instance.call }

    let(:instance) { described_class.new(**options) }

    before do
      instance.instance_variable_set(:@managers, [])
    end

    context "when checking if pristine" do
      before do
        allow(instance).to receive(:warn)
        allow(instance).to receive(:`).with("git status --porcelain").and_return(output)
      end

      context "with the pristine option" do
        let(:options) { { pristine: true } }

        context "when the working directory has changes" do
          let(:output) { "?? lib/" }

          it { expect { call }.to raise_error(SystemExit) }

          it "displays a warning message" do
            begin
              call
            rescue SystemExit # rubocop:disable Lint/SuppressedException
            end

            expect(instance).to have_received(:warn).with("Working directory must be pristine to run.")
          end
        end

        context "when the working directory does not have changes" do
          let(:output) { "\n" }

          it { expect { call }.not_to raise_error }

          it "does not display a warning message" do
            call

            expect(instance).not_to have_received(:warn)
          end
        end
      end

      context "without the pristine option" do
        let(:options) { {} }

        it "does not check if pristine" do
          call

          expect(instance).not_to have_received(:`)
        end

        it "does not display a warning message" do
          call

          expect(instance).not_to have_received(:warn)
        end
      end
    end

    context "when bumping valid managers" do
      let(:options)       { {} }
      let(:ruby_instance) { instance_double(described_class::Managers::Bundler, bump: true) }
      let(:ruby_manager)  { class_double(described_class::Managers::Bundler, new: ruby_instance, valid?: true) }
      let(:yarn_manager)  { class_double(described_class::Managers::Yarn, new: nil, valid?: false) }

      before do
        instance.instance_variable_set(:@managers, nil)

        stub_const("Bumpit::Managers::Bundler", ruby_manager)
        stub_const("Bumpit::Managers::Yarn", yarn_manager)
      end

      it "bumps valid managers" do
        call

        expect(ruby_instance).to have_received(:bump)
      end

      it "does not bump invalid managers" do
        call

        expect(yarn_manager).not_to have_received(:new)
      end
    end

    context "when verifying the changes" do
      context "with the verify option" do
        let(:options) { { verify: "exit 0" } }

        before do
          allow(instance).to receive(:warn)
        end

        it "runs a system command with the verify option" do
          allow(instance).to receive(:system).and_call_original

          call

          expect(instance).to have_received(:system).with("exit 0")
        end

        context "when successful" do
          it { expect { call }.not_to raise_error }

          it "does not display a warning message" do
            call

            expect(instance).not_to have_received(:warn)
          end
        end

        context "when unsuccessful" do
          let(:options) { { verify: "exit 1" } }

          it { expect { call }.to raise_error(SystemExit) }

          it "displays a warning message" do
            begin
              call
            rescue SystemExit # rubocop:disable Lint/SuppressedException
            end

            expect(instance).to have_received(:warn).with("The `exit 1` verification command failed.")
          end

          it "exits with the same status" do
            call
          rescue SystemExit => error
            expect(error.status).to eq(1)
          end
        end
      end

      context "without the verify option" do
        let(:options) { {} }

        before do
          allow(instance).to receive(:system)
        end

        it "does not run a system command" do
          call

          expect(instance).not_to have_received(:system)
        end
      end
    end

    context "when generating a commit message" do
      context "with the commit option" do
        let(:options) { { commit: true } }

        context "with messages" do
          let(:ruby_instance) { instance_double(described_class::Managers::Bundler, bump: nil, message: "ruby " * 16) }
          let(:yarn_instance) { instance_double(described_class::Managers::Yarn, bump: nil, message: "One.") }

          before do
            instance.instance_variable_set(:@managers, [yarn_instance, ruby_instance])
          end

          it "produces messages to output with word wrapping" do
            expect { call }.to output("Update dependencies.\n\n* One.\n* #{("ruby " * 15).strip}\n  ruby\n").to_stdout
          end
        end

        context "without messages" do
          before do
            instance.instance_variable_set(:@managers, [])
          end

          it "does not produce output" do
            expect { call }.not_to output.to_stdout
          end
        end
      end

      context "without the commit option" do
        let(:options) { {} }

        it "does not produce output" do
          expect { call }.not_to output.to_stdout
        end
      end
    end
  end
end
