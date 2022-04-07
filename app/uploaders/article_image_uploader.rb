# frozen_string_literal: true

class ArticleImageUploader < DefaultUploader
  process resize_to_fill: [1920, 1280, :center]

  version :highres do
    process resize_to_fill: [1272, 714, :center]
  end

  def extension_allowlist
    %w[svg jpg jpeg png]
  end
end
