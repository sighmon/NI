class SubscriptionCheckoutOption
  include ActiveModel::Model

  SUPPORTED_DURATIONS = [3, 6, 12].freeze

  attr_reader :duration, :autodebit, :paper, :paper_only, :institution, :special

  def self.available
    @available ||= [
      new(duration: 3, autodebit: true),
      new(duration: 6, autodebit: true),
      new(duration: 12, autodebit: true),
      new(duration: 3, autodebit: false),
      new(duration: 6, autodebit: false),
      new(duration: 12, autodebit: false),
      new(duration: 3, autodebit: true, paper: true),
      new(duration: 6, autodebit: true, paper: true),
      new(duration: 12, autodebit: true, paper: true),
      new(duration: 3, autodebit: false, paper: true),
      new(duration: 6, autodebit: false, paper: true),
      new(duration: 12, autodebit: false, paper: true),
      new(duration: 3, autodebit: false, paper: true, paper_only: true),
      new(duration: 6, autodebit: false, paper: true, paper_only: true),
      new(duration: 12, autodebit: false, paper: true, paper_only: true),
      new(duration: 12, autodebit: true, institution: true),
      new(duration: 12, autodebit: true, paper: true, institution: true),
      new(duration: 12, autodebit: false, institution: true),
      new(duration: 12, autodebit: false, paper: true, institution: true),
      new(duration: 12, autodebit: false, paper: true, paper_only: true, institution: true)
    ]
  end

  def self.from_params(params)
    candidate = new(
      duration: params[:duration],
      autodebit: params[:autodebit],
      paper: params[:paper],
      paper_only: params[:paper_only],
      institution: params[:institution],
      special: params[:special]
    )
    return candidate if candidate.valid?

    nil
  end

  def initialize(duration:, autodebit:, paper: false, paper_only: false, institution: false, special: false)
    @duration = duration.to_i
    @autodebit = cast_boolean(autodebit)
    @paper = cast_boolean(paper)
    @paper_only = cast_boolean(paper_only)
    @institution = cast_boolean(institution)
    @special = cast_boolean(special)
  end

  def valid?
    SUPPORTED_DURATIONS.include?(duration) &&
      (!paper_only? || paper?) &&
      (!autodebit? || !paper_only?) &&
      (!institution? || duration == 12)
  end

  def autodebit?
    autodebit
  end

  def paper?
    paper
  end

  def paper_only?
    paper_only
  end

  def institution?
    institution
  end

  def special?
    special
  end

  def price_cents
    Subscription.calculate_subscription_price(
      duration,
      autodebit: autodebit?,
      paper: paper?,
      paper_only: paper_only?,
      institution: institution?,
      special: special?
    )
  end

  def price_value
    format("%.2f", price_cents / 100.0)
  end

  def key
    [
      duration,
      autodebit? ? "autodebit" : "once",
      paper_only? ? "paper_only" : (paper? ? "paper" : "digital"),
      institution? ? "institution" : "individual",
      special? ? "special" : "standard"
    ].join("_")
  end

  def name
    prefix = institution? ? "Institution " : ""
    access = if paper_only?
      "paper only"
    elsif paper?
      "print and digital"
    else
      "digital"
    end
    cadence = autodebit? ? "automatic renewal every #{duration} months" : "once-off #{duration} month"

    "#{prefix}#{access} subscription, #{cadence}"
  end

  def description
    "New Internationalist Australia #{name}."
  end

  def plan_name
    "New Internationalist #{name.titleize}"
  end

  def purchase_unit_name
    "#{duration}-month #{paper_only? ? 'paper only' : (paper? ? 'print + digital' : 'digital')} subscription"
  end

  def requires_shipping?
    paper? || paper_only?
  end

  def to_h
    {
      duration: duration,
      autodebit: autodebit?,
      paper: paper?,
      paper_only: paper_only?,
      institution: institution?,
      special: special?
    }
  end

  private

  attr_reader :autodebit, :paper, :paper_only, :institution, :special

  def cast_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
