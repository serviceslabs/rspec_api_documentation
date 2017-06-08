require 'acceptance_helper'

resource "Uploads" do
  authentication :apiKey, :value => :api_key, :in => :header, :description => "Api Key description", :name => "Authorization"

  let(:api_key) { "API_KEY" }

  post "/uploads" do
    parameter :file, "New file to upload", :in => :formData, :type => :file

    let(:file) { Rack::Test::UploadedFile.new("spec/fixtures/file.png", "image/png") }

    example_request "Uploading a new file" do
      expect(status).to eq(201)
    end
  end
end
