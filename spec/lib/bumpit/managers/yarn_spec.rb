# frozen_string_literal: true

RSpec.describe Bumpit::Managers::Yarn do
  describe ".valid?" do
    subject { described_class.valid? }

    before do
      allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("package.json")).and_return(true)
      allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("yarn.lock")).and_return(true)
      allow(described_class).to receive(:executable?).with("npm").and_return(true)
      allow(described_class).to receive(:executable?).with("yarn").and_return(true)
    end

    context "when npm, yarn, and all files exist" do
      it { is_expected.to be(true) }
    end

    context "when npm does not exist" do
      before do
        allow(described_class).to receive(:executable?).with("npm").and_return(false)
      end

      it { is_expected.to be(false) }
    end

    context "when yarn does not exist" do
      before do
        allow(described_class).to receive(:executable?).with("yarn").and_return(false)
      end

      it { is_expected.to be(false) }
    end

    context "when package.json does not exist" do
      before do
        allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("package.json")).and_return(false)
      end

      it { is_expected.to be(false) }
    end

    context "when yarn.lock does not exist" do
      before do
        allow(File).to receive(:exist?).with(Pathname.new(Dir.pwd).join("yarn.lock")).and_return(false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe "#bump" do
    subject(:bump) { instance.bump }

    let(:instance) { described_class.new }

    before do
      allow(instance).to receive(:`)
      allow(instance).to receive(:`).with(described_class::OUTDATED_COMMAND).and_return(JSON.dump(updates))
    end

    context "with updates" do
      let(:updates) do
        {
          mocha:  { current: "11.0.0", wanted: "11.0.1", latest: "11.1.0" },
          eslint: { current: "9.21.0", wanted: "9.20.1", latest: "9.21.0" }
        }
      end

      it "attempts to upgrade packages" do
        bump

        expect(instance).to have_received(:`).with(%(yarn up --exact "*"))
      end

      it "removes the lock file" do
        bump

        expect(instance).to have_received(:`).with("rm yarn.lock")
      end

      it "generates a new lock file" do
        bump

        expect(instance).to have_received(:`).with("yarn")
      end
    end

    context "with no updates" do
      let(:updates) { {} }

      it "does not attempt to upgrade packages" do
        bump

        expect(instance).not_to have_received(:`).with(%(yarn up --exact "*"))
      end

      it "does not remove the lock file" do
        bump

        expect(instance).not_to have_received(:`).with("rm yarn.lock")
      end

      it "does not generate a new lock file" do
        bump

        expect(instance).not_to have_received(:`).with("yarn")
      end
    end
  end

  describe "#message" do
    subject { instance.message }

    let(:instance) { described_class.new }

    before do
      allow(instance).to receive(:`).with(described_class::OUTDATED_COMMAND).and_return(JSON.dump(updates))
    end

    context "with updates" do
      let(:updates) do
        {
          mocha:  { current: "11.0.0", wanted: "11.0.1", latest: "11.1.0" },
          eslint: { current: "9.21.0", wanted: "9.20.1", latest: "9.21.0" }
        }
      end

      it { is_expected.to eq("Updates eslint and mocha in JavaScript.") }
    end

    context "with no updates" do
      let(:updates) { [] }

      it { is_expected.to be_nil }
    end
  end
end
