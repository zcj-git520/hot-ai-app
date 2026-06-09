sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure { const NetworkFailure([super.message = '网络异常']); }
class TimeoutFailure extends Failure { const TimeoutFailure([super.message = '请求超时']); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure([super.message = '未登录']); }
class NotFoundFailure extends Failure { const NotFoundFailure([super.message = '资源不存在']); }
class ServerFailure extends Failure { const ServerFailure(super.message); }
class UnknownFailure extends Failure { const UnknownFailure([super.message = '未知错误']); }
