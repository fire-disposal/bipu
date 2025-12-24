/// 输入验证器
library;

/// 邮箱验证器
class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  static bool isValid(String email) {
    return _emailRegex.hasMatch(email);
  }

  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return '邮箱不能为空';
    }
    if (!isValid(email)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }
}

/// 密码验证器
class PasswordValidator {
  static const int minLength = 6;
  static const int maxLength = 20;

  static bool isValid(String password) {
    return password.length >= minLength && password.length <= maxLength;
  }

  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return '密码不能为空';
    }
    if (password.length < minLength) {
      return '密码长度不能少于$minLength位';
    }
    if (password.length > maxLength) {
      return '密码长度不能超过$maxLength位';
    }
    return null;
  }

  static String? validateConfirmation(String? password, String? confirmation) {
    if (password != confirmation) {
      return '两次输入的密码不一致';
    }
    return null;
  }
}

/// 用户名验证器
class UsernameValidator {
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static bool isValid(String username) {
    return _usernameRegex.hasMatch(username);
  }

  static String? validate(String? username) {
    if (username == null || username.isEmpty) {
      return '用户名不能为空';
    }
    if (!isValid(username)) {
      return '用户名只能包含字母、数字和下划线，长度3-20位';
    }
    return null;
  }
}

/// 设备ID验证器
class DeviceIdValidator {
  static final RegExp _deviceIdRegex = RegExp(
    r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
  );

  static bool isValid(String deviceId) {
    return _deviceIdRegex.hasMatch(deviceId);
  }

  static String? validate(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) {
      return '设备ID不能为空';
    }
    if (!isValid(deviceId)) {
      return '请输入有效的设备ID格式 (如: 00:11:22:33:44:55)';
    }
    return null;
  }
}

/// 通用验证器
class CommonValidator {
  static String? notEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName不能为空';
    }
    return null;
  }

  static String? minLength(String? value, int min, String fieldName) {
    if (value != null && value.length < min) {
      return '$fieldName长度不能少于$min个字符';
    }
    return null;
  }

  static String? maxLength(String? value, int max, String fieldName) {
    if (value != null && value.length > max) {
      return '$fieldName长度不能超过$max个字符';
    }
    return null;
  }

  static String? range(num? value, num min, num max, String fieldName) {
    if (value != null && (value < min || value > max)) {
      return '$fieldName必须在$min到$max之间';
    }
    return null;
  }
}
