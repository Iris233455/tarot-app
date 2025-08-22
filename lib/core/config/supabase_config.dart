class SupabaseConfig {
  // Supabase 项目配置
  static const String supabaseUrl = 'https://wpblulcekjnhwccrjqlg.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwYmx1bGNla2puaHdjY3JqcWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2MTQxNDYsImV4cCI6MjA2NzE5MDE0Nn0.nBD1Ufq8-c7jVUXqIm0qU49Qm6QACCb7p-E-A50sK-U';

  // 可选：指定前端公开访问的基础URL，用于Supabase重定向
  // 通过 --dart-define=APP_PUBLIC_URL=http://localhost:xxxx 注入
  static const String appPublicUrl = String.fromEnvironment('APP_PUBLIC_URL', defaultValue: '');

  // 原生平台使用的自定义Scheme回调（开发期）
  static const String nativeCallbackUrl = 'mystictarot://password-reset-complete';
} 