require 'sfctl/commands/time/providers/unset'

RSpec.describe Sfctl::Commands::Time::Providers::Unset, type: :unit do
  let(:config_file) { '.sfctl' }
  let(:output) { StringIO.new }
  let(:options) do
    { 'no-color' => true }
  end
  let(:toggl_provider) { 'toggl' }
  let(:harvest_provider) { 'harvest' }

  before do
    stub_const('Sfctl::Command::CONFIG_PATH', tmp_path(config_file))
  end

  it 'should shown an error if .sfctl is not initialized' do
    described_class.new(options).execute(output: output)

    expect(output.string).to include 'Please authentificate before continue.'
  end

  it 'should ask for replace if toggl provider alredy defined' do
    ::FileUtils.touch tmp_path(config_file)
    File.write tmp_path(config_file), "---\naccess_token: correctToken"

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "[#{toggl_provider}] is already deleted from configuration."
  end

  it 'should ask for replace if harvest provider alredy defined' do
    ::FileUtils.touch tmp_path(config_file)
    File.write tmp_path(config_file), "---\naccess_token: correctToken"

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(harvest_provider)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "[#{harvest_provider}] is already deleted from configuration."
  end

  it 'should unset a toggl provider' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(File.file?(tmp_path(config_file))).to be_truthy

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(toggl_provider)
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Do you want to remove the delete the configuration?')
      .and_return(true)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Configuration for provider [#{toggl_provider}] was successfully deleted."

    file_data = File.read(tmp_path(config_file))
    expect(file_data).to include harvest_provider
    expect(file_data).not_to include toggl_provider
  end

  it 'should unset a harvest provider' do
    config_path = fixtures_path(config_file)
    ::FileUtils.cp(config_path, tmp_path(config_file))
    expect(File.file?(tmp_path(config_file))).to be_truthy

    expect_any_instance_of(TTY::Prompt).to receive(:select).and_return(harvest_provider)
    expect_any_instance_of(TTY::Prompt).to receive(:yes?).with('Do you want to remove the delete the configuration?')
      .and_return(true)

    described_class.new(options).execute(output: output)

    expect(output.string).to include "Configuration for provider [#{harvest_provider}] was successfully deleted."

    file_data = File.read(tmp_path(config_file))
    expect(file_data).to include toggl_provider
    expect(file_data).not_to include harvest_provider
  end
end
