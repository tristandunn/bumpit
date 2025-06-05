# frozen_string_literal: true

RSpec.describe Bumpit::Managers::Bundler do
  describe ".valid?" do
    subject { described_class.valid? }

    before do
      allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("Gemfile")).and_return(true)
      allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("Gemfile.lock")).and_return(true)
      allow(described_class).to receive(:executable?).with("bundle").and_return(true)
    end

    context "when bundle and all files exist" do
      it { is_expected.to be(true) }
    end

    context "when bundle does not exist" do
      before do
        allow(described_class).to receive(:executable?).with("bundle").and_return(false)
      end

      it { is_expected.to be(false) }
    end

    context "when Gemfile does not exist" do
      before do
        allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("Gemfile")).and_return(false)
      end

      it { is_expected.to be(false) }
    end

    context "when Gemfile.lock does not exist" do
      before do
        allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("Gemfile.lock")).and_return(false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe "#bump" do
    subject(:bump) { instance.bump }

    let(:instance) { described_class.new }
    let(:update)   { instance_double(Bundler::CLI::Update, run: true) }

    before do
      allow(Bundler).to receive(:clear_gemspec_cache)
      allow(Bundler).to receive(:reset!)
      allow(Bundler).to receive(:reset_settings_and_root!)
      allow(Bundler::CLI::Update).to receive(:new).with({ all: true }, []).and_return(update)
      allow(File).to receive(:read).and_return(%(gem "json", "2.10.1"\ngem 'sqlite3', '2.5.0'))
      allow(File).to receive(:write)
      allow(instance).to receive(:`).with(described_class::BUNDLER_UPDATE_COMMAND)
      allow(instance).to receive(:`).with(described_class::BUNDLE_VERSION_COMMAND).and_return("2.6.8")
      allow(instance).to receive(:`).with(described_class::GEM_INFO_COMMAND).and_return(info)
      allow(instance).to receive(:`).with(described_class::OUTDATED_COMMAND).and_return(updates)
      allow(instance).to receive(:silence_output).and_yield
    end

    context "with a Bundler update" do
      let(:updates) { "" }

      let(:info) do
        <<~RUBYGEMS
          bundler (2.7.1)
              Authors: André Arko, Samuel Giddins, Colby Swandale, Hiroshi
              Shibata, David Rodríguez, Grey Baker, Stephanie Morillo, Chris
              Morris, James Wen, Tim Moore, André Medeiros, Jessica Lynn Suttles,
              Terence Lee, Carl Lerche, Yehuda Katz
              Homepage: https://bundler.io
              License: MIT

              The best way to manage your application's dependencies
        RUBYGEMS
      end

      it "updates Bundler to the latest version" do
        bump

        expect(instance).to have_received(:`).with(described_class::BUNDLER_UPDATE_COMMAND)
      end
    end

    context "with updates" do
      let(:info) { "" }

      let(:updates) do
        <<~GEMFILE
          Resolving dependencies...

          sqlite3 (newest 2.6.0, installed 2.5.0, requested = 2.5.0)
        GEMFILE
      end

      it "reads the existing Gemfile" do
        bump

        expect(File).to have_received(:read).with("Gemfile")
      end

      it "writes a new Gemfile" do
        bump

        expect(File).to have_received(:write).with("Gemfile", %(gem "json", "2.10.1"\ngem 'sqlite3', '2.6.0'\n))
      end

      it "silences the update output" do
        bump

        expect(instance).to have_received(:silence_output).with(no_args)
      end

      it "clears the gemspec cache" do
        bump

        expect(Bundler).to have_received(:clear_gemspec_cache).with(no_args)
      end

      it "resets Bundler" do
        bump

        expect(Bundler).to have_received(:reset!).with(no_args)
      end

      it "resets Bundler settings" do
        bump

        expect(Bundler).to have_received(:reset_settings_and_root!).with(no_args)
      end

      it "updates dependencies with bundler" do
        bump

        expect(update).to have_received(:run).with(no_args)
      end
    end

    context "with no updates" do
      let(:info)    { "" }
      let(:updates) { "" }

      it "does not attempt to read the Gemfile" do
        bump

        expect(File).not_to have_received(:read)
      end

      it "does not attempt to write to the Gemfile" do
        bump

        expect(File).not_to have_received(:write)
      end

      it "does not clear the gemspec cache" do
        bump

        expect(Bundler).not_to have_received(:clear_gemspec_cache)
      end

      it "does not reset Bundler" do
        bump

        expect(Bundler).not_to have_received(:reset!)
      end

      it "does not reset Bundler settings" do
        bump

        expect(Bundler).not_to have_received(:reset_settings_and_root!)
      end

      it "does not update dependencies with bundler" do
        bump

        expect(Bundler::CLI::Update).not_to have_received(:new)
      end
    end
  end

  describe "#message" do
    subject { instance.message }

    let(:instance) { described_class.new }

    before do
      allow(instance).to receive(:`).with(described_class::BUNDLE_VERSION_COMMAND).and_return("2.6.8")
      allow(instance).to receive(:`).with(described_class::GEM_INFO_COMMAND).and_return(info)
      allow(instance).to receive(:`).with(described_class::OUTDATED_COMMAND).and_return(updates)
    end

    context "with updates" do
      let(:info) { "" }

      let(:updates) do
        <<~GEMFILE
          Resolving dependencies...

          sqlite3 (newest 2.6.0, installed 2.5.0, requested = 2.5.0)
          rubocop (newest 1.72.2, installed 1.72.1, requested = 1.72.1)
        GEMFILE
      end

      it { is_expected.to eq("Updates rubocop and sqlite3 in Ruby.") }
    end

    context "with a Bundler update" do
      let(:updates) { "" }

      let(:info) do
        <<~RUBYGEMS
          bundler (2.7.1)
              Authors: André Arko, Samuel Giddins, Colby Swandale, Hiroshi
              Shibata, David Rodríguez, Grey Baker, Stephanie Morillo, Chris
              Morris, James Wen, Tim Moore, André Medeiros, Jessica Lynn Suttles,
              Terence Lee, Carl Lerche, Yehuda Katz
              Homepage: https://bundler.io
              License: MIT

              The best way to manage your application's dependencies
        RUBYGEMS
      end

      before do
        allow(instance).to receive(:`).with(described_class::BUNDLER_UPDATE_COMMAND)

        instance.bump
      end

      it { is_expected.to eq("Updates bundler in Ruby.") }
    end

    context "with no updates" do
      let(:info)    { "" }
      let(:updates) { "Resolving dependencies...\n\n" }

      it { is_expected.to be_nil }
    end
  end
end
