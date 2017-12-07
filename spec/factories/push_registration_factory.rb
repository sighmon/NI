FactoryBot.define do

  factory :push_registration do
    token "<00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000>"
    device "ios"

    factory :android_push_registration do
      token "000000000000000000000000000000000000000000000000000000000000000"
      device "android"
    end
  end

end
