require 'spec_helper'
require 'queries/droplet_list_fetcher'
require 'messages/droplets_list_message'

module VCAP::CloudController
  describe DropletListFetcher do
    subject(:fetcher) { described_class.new(message: message) }
    let(:pagination_options) { PaginationOptions.new({}) }
    let(:message) { DropletsListMessage.new(filters) }
    let(:filters) { {} }

    describe '#fetch_all' do
      let(:app1) { AppModel.make }
      let!(:staged_droplet_for_app1) { DropletModel.make(app_guid: app1.guid, state: DropletModel::STAGED_STATE) }
      let!(:failed_droplet_for_app1) { DropletModel.make(app_guid: app1.guid, state: DropletModel::FAILED_STATE) }

      let(:app2) { AppModel.make }
      let!(:pending_droplet_for_app2) { DropletModel.make(app_guid: app2.guid, state: DropletModel::PENDING_STATE) }

      it 'returns a Sequel::Dataset' do
        results = fetcher.fetch_all
        expect(results).to be_a(Sequel::Dataset)
      end

      it 'returns all of the droplets' do
        results = fetcher.fetch_all
        expect(results).to match_array([staged_droplet_for_app1, failed_droplet_for_app1, pending_droplet_for_app2])
      end

      context 'filtering space guids' do
        let(:filters) { { space_guids: [app1.space.guid] } }

        it 'returns all of the droplets with the requested app guids' do
          results = fetcher.fetch_all.all
          expect(results.map(&:guid)).to match_array([staged_droplet_for_app1.guid, failed_droplet_for_app1.guid])
        end
      end

      context 'filtering app guids' do
        let(:filters) { { app_guids: [app1.guid] } }

        it 'returns all of the droplets with the requested app guids' do
          results = fetcher.fetch_all.all
          expect(results).to match_array([staged_droplet_for_app1, failed_droplet_for_app1])
        end
      end

      context 'filtering states' do
        let(:filters) { { states: [DropletModel::STAGED_STATE, DropletModel::PENDING_STATE] } }
        let!(:pending_droplet_for_other_app) { DropletModel.make(state: DropletModel::PENDING_STATE) }

        it 'returns all of the droplets with the requested states' do
          results = fetcher.fetch_all.all
          expect(results).to match_array([staged_droplet_for_app1, pending_droplet_for_app2, pending_droplet_for_other_app])
        end
      end

      context 'filtering guids' do
        let(:filters) { { guids: [staged_droplet_for_app1.guid, failed_droplet_for_app1.guid] } }

        it 'returns all of the droplets with the requested guids' do
          results = fetcher.fetch_all.all
          expect(results).to match_array([staged_droplet_for_app1, failed_droplet_for_app1])
        end
      end
    end

    describe '#fetch_for_spaces' do
      let(:space1) { app1.space }
      let(:app1) { AppModel.make }
      let!(:staged_droplet_for_app1) { DropletModel.make(app_guid: app1.guid, state: DropletModel::STAGED_STATE) }
      let!(:failed_droplet_for_app1) { DropletModel.make(app_guid: app1.guid, state: DropletModel::FAILED_STATE) }

      let(:app2) { AppModel.make }
      let(:space2) { app2.space }
      let!(:pending_droplet_for_app2) { DropletModel.make(app_guid: app2.guid, state: DropletModel::PENDING_STATE) }

      let(:app3) { AppModel.make }
      let(:space3) { app3.space }
      let!(:pending_droplet_for_app3) { DropletModel.make(app_guid: app3.guid, state: DropletModel::PENDING_STATE) }

      let(:space_guids) { [space1.guid, space2.guid] }

      it 'returns a Sequel::Dataset' do
        results = fetcher.fetch_for_spaces(space_guids: space_guids)
        expect(results).to be_a(Sequel::Dataset)
      end

      it 'returns all of the desired droplets in the requested spaces' do
        results = fetcher.fetch_for_spaces(space_guids: space_guids).all
        expect(results.map(&:guid)).to match_array([staged_droplet_for_app1.guid, failed_droplet_for_app1.guid, pending_droplet_for_app2.guid])
      end

      context 'filtering app guids' do
        let(:filters) { { app_guids: [app2.guid, app3.guid] } }
        let(:space_guids) { [space1.guid, space2.guid, space3.guid] }

        it 'returns all of the desired droplets for the requested app guids' do
          results = fetcher.fetch_for_spaces(space_guids: space_guids).all
          expect(results).to match_array([pending_droplet_for_app2, pending_droplet_for_app3])
        end
      end

      context 'filtering states' do
        let(:filters) { { states: [DropletModel::PENDING_STATE, DropletModel::FAILED_STATE] } }
        let(:space_guids) { [space1.guid, space2.guid, space3.guid] }

        it 'returns all of the desired droplets with the requested droplet states' do
          results = fetcher.fetch_for_spaces(space_guids: space_guids).all
          expect(results).to match_array([failed_droplet_for_app1, pending_droplet_for_app2, pending_droplet_for_app3])
        end
      end

      context 'filtering guids' do
        let(:filters) { { guids: [failed_droplet_for_app1.guid, pending_droplet_for_app2.guid] } }

        it 'returns all of the desired droplets with the requested droplet guids' do
          results = fetcher.fetch_for_spaces(space_guids: space_guids).all
          expect(results).to match_array([failed_droplet_for_app1, pending_droplet_for_app2])
        end
      end

      context 'filtering space guids' do
        let(:filters) { { space_guids: [failed_droplet_for_app1.space.guid] } }

        it 'returns all of the desired droplets with the requested space guids' do
          results = fetcher.fetch_for_spaces(space_guids: space_guids).all
          expect(results.map(&:guid)).to match_array([failed_droplet_for_app1.guid, staged_droplet_for_app1.guid])
        end
      end
    end

    describe '#fetch_for_app' do
      let(:app) { AppModel.make }
      let!(:staged_droplet) { DropletModel.make(app_guid: app.guid, state: DropletModel::STAGED_STATE) }
      let!(:failed_droplet) { DropletModel.make(app_guid: app.guid, state: DropletModel::FAILED_STATE) }
      let(:filters) { { app_guid: app.guid } }

      it 'returns a Sequel::Dataset' do
        _app, results = fetcher.fetch_for_app
        expect(results).to be_a(Sequel::Dataset)
      end

      it 'returns the app' do
        returned_app, _results = fetcher.fetch_for_app
        expect(returned_app.guid).to eq(app.guid)
      end

      it 'returns all of the desired droplets for the requested app' do
        _app, results = fetcher.fetch_for_app
        expect(results.all).to match_array([staged_droplet, failed_droplet])
      end

      context 'when app does not exist' do
        let(:filters) { { app_guid: 'made up guid lol' } }
        it 'returns nil' do
          returned_app, results = fetcher.fetch_for_app
          expect(returned_app).to be_nil
          expect(results).to be_nil
        end
      end

      context 'filtering states' do
        let(:filters) { { states: [DropletModel::FAILED_STATE], app_guid: app.guid } }
        let!(:failed_droplet_not_on_app) { DropletModel.make(state: DropletModel::FAILED_STATE) }

        it 'returns all of the desired droplets with the requested droplet states' do
          _app, results = fetcher.fetch_for_app
          expect(results.all).to match_array([failed_droplet])
        end
      end
    end
  end
end
