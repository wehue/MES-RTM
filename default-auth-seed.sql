-- MES-RTM default auth seed data.
-- Import this script after the base schema has been created.
-- Default password for all seeded users: 123456

SET NAMES utf8mb4;

INSERT INTO smt_roles
  (RoleCode, RoleName, Description, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
VALUES
  ('RTM_ADMIN', 'RTM管理员', 'MES-RTM 实时制造执行子系统管理员，拥有 RTM 端全部功能权限', 'seed', 'seed', 0, 1),
  ('PRODUCTION_SUPERVISOR', '生产主管', '负责工单、批次计划与调度，统筹产线生产执行与工单收尾', 'seed', 'seed', 0, 1),
  ('LEADER', '班组长', '负责现场执行协调、进站、上料、出站与异常跟进', 'seed', 'seed', 0, 1),
  ('OPERATOR', '操作工', '负责上料、进站、出站、批次执行数据录入', 'seed', 'seed', 0, 1),
  ('QUALITY_ENGINEER', '质量工程师', '负责质量拦截、维修处理和参数质量追溯', 'seed', 'seed', 0, 1)
ON DUPLICATE KEY UPDATE
  RoleName = VALUES(RoleName),
  Description = VALUES(Description),
  UpdatedBy = 'seed',
  IsDeleted = 0,
  LastOperationType = 2;

INSERT INTO smt_functions
  (FunctionCode, FunctionName, Description, CreatedBy, UpdatedBy, IsDeleted, LastOperationType, Subsystem)
VALUES
  ('dashboard', '首页', '生产驾驶舱、产线负载和核心指标总览', 'seed', 'seed', 0, 1, 2),
  ('kanban', '看板中心', '产线状态看板、质量看板和生产进度看板', 'seed', 'seed', 0, 1, 2),
  ('work_order', '工单管理', '查看工单列表，支持创建、释放、暂停、关闭工单', 'seed', 'seed', 0, 1, 2),
  ('batch', '批次管理', '创建、锁定批次，记录批次状态和当前工序', 'seed', 'seed', 0, 1, 2),
  ('loading', '上料管理', '显示当前批次所需上料的站位物料清单并执行补料', 'seed', 'seed', 0, 1, 2),
  ('check_in', '进站操作', '校验批次进站权限并记录进站数量和设备', 'seed', 'seed', 0, 1, 2),
  ('check_out', '出站操作', '记录出站时间、完工数量、不良数量和处置方式', 'seed', 'seed', 0, 1, 2),
  ('tracking', '批次跟踪', '查询批次工艺参数、上料记录和质量结果', 'seed', 'seed', 0, 1, 2),
  ('repair', '维修管理', '查看待维修批次并记录维修情况', 'seed', 'seed', 0, 1, 2),
  ('equipment', '设备管理', '设备档案、设备状态、设备类型管理', 'seed', 'seed', 0, 1, 2),
  ('system', '系统中心', '个人中心、消息通知和基础系统入口', 'seed', 'seed', 0, 1, 2)
ON DUPLICATE KEY UPDATE
  FunctionName = VALUES(FunctionName),
  Description = VALUES(Description),
  UpdatedBy = 'seed',
  IsDeleted = 0,
  LastOperationType = 2,
  Subsystem = VALUES(Subsystem);

INSERT INTO smt_users
  (Username, PasswordHash, FullName, Department, Position, Contact, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
VALUES
  ('admin', 'e10adc3949ba59abbe56e057f20f883e', '系统管理员', '信息部', 'RTM管理员', 'admin@factory.local', 'seed', 'seed', 0, 1),
  ('pm01', 'e10adc3949ba59abbe56e057f20f883e', '王主管', '生产部', '生产主管', 'pm01@factory.local', 'seed', 'seed', 0, 1),
  ('tl01', 'e10adc3949ba59abbe56e057f20f883e', '李班长', 'SMT车间', '班组长', 'tl01@factory.local', 'seed', 'seed', 0, 1),
  ('op01', 'e10adc3949ba59abbe56e057f20f883e', '张工', 'SMT车间', '操作工', 'op01@factory.local', 'seed', 'seed', 0, 1),
  ('qe01', 'e10adc3949ba59abbe56e057f20f883e', '质量工程师', '质量部', '质量工程师', 'qe01@factory.local', 'seed', 'seed', 0, 1)
ON DUPLICATE KEY UPDATE
  PasswordHash = VALUES(PasswordHash),
  FullName = VALUES(FullName),
  Department = VALUES(Department),
  Position = VALUES(Position),
  Contact = VALUES(Contact),
  UpdatedBy = 'seed',
  IsDeleted = 0,
  LastOperationType = 2;

INSERT INTO smt_role_functions
  (RoleId, FunctionId, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
SELECT r.Id, f.Id, 'seed', 'seed', 0, 1
FROM smt_roles r
JOIN smt_functions f
WHERE r.RoleCode = 'RTM_ADMIN'
  AND f.FunctionCode IN (
    'dashboard', 'kanban', 'work_order', 'batch', 'loading',
    'check_in', 'check_out', 'tracking', 'repair', 'equipment', 'system'
  )
ON DUPLICATE KEY UPDATE IsDeleted = 0, UpdatedBy = 'seed', LastOperationType = 2;

INSERT INTO smt_role_functions
  (RoleId, FunctionId, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
SELECT r.Id, f.Id, 'seed', 'seed', 0, 1
FROM smt_roles r
JOIN smt_functions f
WHERE r.RoleCode = 'PRODUCTION_SUPERVISOR'
  AND f.FunctionCode IN ('dashboard', 'kanban', 'work_order', 'batch', 'tracking', 'equipment', 'system')
ON DUPLICATE KEY UPDATE IsDeleted = 0, UpdatedBy = 'seed', LastOperationType = 2;

INSERT INTO smt_role_functions
  (RoleId, FunctionId, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
SELECT r.Id, f.Id, 'seed', 'seed', 0, 1
FROM smt_roles r
JOIN smt_functions f
WHERE r.RoleCode = 'LEADER'
  AND f.FunctionCode IN ('dashboard', 'kanban', 'loading', 'check_in', 'check_out', 'tracking', 'repair', 'equipment', 'system')
ON DUPLICATE KEY UPDATE IsDeleted = 0, UpdatedBy = 'seed', LastOperationType = 2;

INSERT INTO smt_role_functions
  (RoleId, FunctionId, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
SELECT r.Id, f.Id, 'seed', 'seed', 0, 1
FROM smt_roles r
JOIN smt_functions f
WHERE r.RoleCode = 'OPERATOR'
  AND f.FunctionCode IN ('dashboard', 'kanban', 'loading', 'check_in', 'check_out', 'tracking', 'system')
ON DUPLICATE KEY UPDATE IsDeleted = 0, UpdatedBy = 'seed', LastOperationType = 2;

INSERT INTO smt_role_functions
  (RoleId, FunctionId, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
SELECT r.Id, f.Id, 'seed', 'seed', 0, 1
FROM smt_roles r
JOIN smt_functions f
WHERE r.RoleCode = 'QUALITY_ENGINEER'
  AND f.FunctionCode IN ('dashboard', 'kanban', 'batch', 'check_out', 'repair', 'tracking', 'equipment', 'system')
ON DUPLICATE KEY UPDATE IsDeleted = 0, UpdatedBy = 'seed', LastOperationType = 2;

INSERT INTO smt_user_roles
  (UserId, RoleId, CreatedBy, UpdatedBy, IsDeleted, LastOperationType)
SELECT u.Id, r.Id, 'seed', 'seed', 0, 1
FROM smt_users u
JOIN smt_roles r
WHERE (u.Username = 'admin' AND r.RoleCode = 'RTM_ADMIN')
   OR (u.Username = 'pm01' AND r.RoleCode = 'PRODUCTION_SUPERVISOR')
   OR (u.Username = 'tl01' AND r.RoleCode = 'LEADER')
   OR (u.Username = 'op01' AND r.RoleCode = 'OPERATOR')
   OR (u.Username = 'qe01' AND r.RoleCode = 'QUALITY_ENGINEER')
ON DUPLICATE KEY UPDATE IsDeleted = 0, UpdatedBy = 'seed', LastOperationType = 2;
