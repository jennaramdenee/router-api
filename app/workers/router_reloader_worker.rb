class RouterReloaderWorker
  include Sidekiq::Worker

  def perform
    RouterReloader.reload
  end
end
