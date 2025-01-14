# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryMetadata::BaseBuilder do
  describe '#execute' do
    subject { described_class.new(xml: xml, data: data).execute }

    let(:xml) { nil }
    let(:data) { {} }

    before do
      stub_const("#{described_class}::ROOT_TAG", 'test')
      stub_const("#{described_class}::ROOT_ATTRIBUTES", { foo1: 'bar1', foo2: 'bar2' })
    end

    it 'generate valid xml' do
      result = Nokogiri::XML::Document.parse(subject)

      expect(result.children.count).to eq(1)
      expect(result.children.first.attributes.count).to eq(2)
      expect(result.children.first.attributes['foo1'].value).to eq('bar1')
      expect(result.children.first.attributes['foo2'].value).to eq('bar2')
    end

    context 'when call with parameters' do
      let(:xml) { 'test' }

      it 'raise NotImplementedError' do
        expect { subject }.to raise_error NotImplementedError
      end
    end
  end
end
