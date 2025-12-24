/// Core 模块主入口
/// 提供应用的核心功能，供 app_user 和 app_admin 共用
///
/// 主要功能：
/// - Foundation: 基础工具类（日志、常量、验证器）
/// - Data: 数据访问和存储（API客户端、JWT存储、数据模型）
/// - Domain: 业务逻辑层（认证服务、BLE服务）
/// - Injection: 依赖注入和服务定位
library;

export 'foundation/foundation.dart';
export 'data/data.dart' hide LogLevel;
export 'domain/domain.dart';
export 'injection/injection.dart';
export 'app_initializer.dart';
export 'app_theme.dart';
