/*
 Navicat Premium Dump SQL

 Source Server         : mysql
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : smt_mes

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 21/06/2026 21:43:41
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for smt_bom
-- ----------------------------
DROP TABLE IF EXISTS `smt_bom`;
CREATE TABLE `smt_bom`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `ProductId` bigint NOT NULL COMMENT '产品ID（逻辑关联 smt_products.Id）',
  `BomVersion` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'BOM版本号（如 V1.0, V2.0）',
  `IsActive` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否激活: 0-历史版本, 1-当前生效版本',
  `Description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '版本描述/变更说明',
  `ActiveProductKey` bigint GENERATED ALWAYS AS ((case when (`IsActive` = 1) then `ProductId` else NULL end)) STORED COMMENT '激活产品唯一键，配合下方 uq_bom_active 约束确保同一产品仅允许一个激活版本' NULL,
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_bom_version`(`ProductId` ASC, `BomVersion` ASC) USING BTREE,
  UNIQUE INDEX `uq_bom_active`(`ActiveProductKey` ASC) USING BTREE,
  INDEX `idx_bom_product`(`ProductId` ASC) USING BTREE,
  INDEX `idx_bom_active`(`IsActive` ASC) USING BTREE,
  CONSTRAINT `fk_bom_product` FOREIGN KEY (`ProductId`) REFERENCES `smt_products` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 14 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'BOM版本头表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_bom
-- ----------------------------
INSERT INTO `smt_bom` VALUES (13, 12, 'TAPI-BOM-V1', b'1', '测试批次BOM', DEFAULT, '2026-06-21 21:32:10.779', 'test', '2026-06-21 21:32:10.779', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_bom_items
-- ----------------------------
DROP TABLE IF EXISTS `smt_bom_items`;
CREATE TABLE `smt_bom_items`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `BomId` bigint NOT NULL COMMENT 'BOM版本ID（逻辑关联 smt_bom.Id）',
  `MaterialId` bigint NOT NULL COMMENT '物料ID（逻辑关联 smt_materials.Id）',
  `ReferenceDesignator` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '位号（如 R1, C3, U2）',
  `Quantity` decimal(10, 3) NOT NULL COMMENT '单板用量',
  `PackageType` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '封装类型（如 0201, 0402, QFP）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_bom_item`(`BomId` ASC, `MaterialId` ASC, `ReferenceDesignator` ASC) USING BTREE,
  INDEX `idx_bom`(`BomId` ASC) USING BTREE,
  INDEX `idx_material`(`MaterialId` ASC) USING BTREE,
  CONSTRAINT `fk_bom_item_bom` FOREIGN KEY (`BomId`) REFERENCES `smt_bom` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_bom_item_material` FOREIGN KEY (`MaterialId`) REFERENCES `smt_materials` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 40 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'BOM行项' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_bom_items
-- ----------------------------
INSERT INTO `smt_bom_items` VALUES (37, 13, 26, 'R1-R5', 500.000, '0201', '2026-06-21 21:32:10.781', 'test', '2026-06-21 21:32:10.781', 'test', b'0', 1, NULL);
INSERT INTO `smt_bom_items` VALUES (38, 13, 27, 'C1-C10', 1000.000, '0402', '2026-06-21 21:32:10.782', 'test', '2026-06-21 21:32:10.782', 'test', b'0', 1, NULL);
INSERT INTO `smt_bom_items` VALUES (39, 13, 28, 'U1', 100.000, 'QFP', '2026-06-21 21:32:10.785', 'test', '2026-06-21 21:32:10.785', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_equipment
-- ----------------------------
DROP TABLE IF EXISTS `smt_equipment`;
CREATE TABLE `smt_equipment`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `EquipmentCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '设备编号（业务唯一）',
  `EquipmentName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '设备名称',
  `EquipmentTypeId` bigint NOT NULL COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id）',
  `Model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '设备型号',
  `Brand` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '品牌',
  `SerialNumber` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '出厂序列号',
  `ProductionDate` date NULL DEFAULT NULL COMMENT '投产日期',
  `WarrantyExpireDate` date NULL DEFAULT NULL COMMENT '保修截止日期',
  `LineId` bigint NULL DEFAULT NULL COMMENT '所属产线ID（逻辑关联 smt_lines.Id，模块2）',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '设备状态: 1-运行, 2-待机, 3-故障, 4-保养, 5-离线, 6-报废',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_equipment_code`(`EquipmentCode` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  INDEX `idx_line`(`LineId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  INDEX `idx_equipment_name`(`EquipmentName` ASC) USING BTREE,
  CONSTRAINT `fk_equipment_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_equipment_line` FOREIGN KEY (`LineId`) REFERENCES `smt_lines` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_equipment_status` CHECK (`Status` between 1 and 6)
) ENGINE = InnoDB AUTO_INCREMENT = 14 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'SMT设备档案' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_equipment
-- ----------------------------
INSERT INTO `smt_equipment` VALUES (11, 'TAPI-EQ-PR-01', '测试印刷机01', 9016, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-06-21 21:32:10.732', 'test', '2026-06-21 21:32:10.732', 'test', b'0', 1, NULL);
INSERT INTO `smt_equipment` VALUES (12, 'TAPI-EQ-SP-01', '测试SPI01', 9017, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-06-21 21:32:10.735', 'test', '2026-06-21 21:32:10.735', 'test', b'0', 1, NULL);
INSERT INTO `smt_equipment` VALUES (13, 'TAPI-EQ-RF-01', '测试回流炉01', 9018, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-06-21 21:32:10.738', 'test', '2026-06-21 21:32:10.738', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_equipment_package_types
-- ----------------------------
DROP TABLE IF EXISTS `smt_equipment_package_types`;
CREATE TABLE `smt_equipment_package_types`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `EquipmentTypeId` bigint NOT NULL COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id）',
  `PackageType` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '封装类型（如 0201, 0402, QFP, BGA）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_equipment_package`(`EquipmentTypeId` ASC, `PackageType` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  INDEX `idx_package_type`(`PackageType` ASC) USING BTREE,
  CONSTRAINT `fk_equip_pkg_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '设备类型与封装类型匹配表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_equipment_package_types
-- ----------------------------
INSERT INTO `smt_equipment_package_types` VALUES (12, 9016, '0201', '2026-06-21 21:32:10.765', 'test', '2026-06-21 21:32:10.765', 'test', b'0', 1, NULL);
INSERT INTO `smt_equipment_package_types` VALUES (13, 9016, '0402', '2026-06-21 21:32:10.767', 'test', '2026-06-21 21:32:10.767', 'test', b'0', 1, NULL);
INSERT INTO `smt_equipment_package_types` VALUES (14, 9016, 'QFP', '2026-06-21 21:32:10.769', 'test', '2026-06-21 21:32:10.769', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_equipment_types
-- ----------------------------
DROP TABLE IF EXISTS `smt_equipment_types`;
CREATE TABLE `smt_equipment_types`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TypeCode` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '设备类型编码',
  `TypeName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '设备类型名称',
  `TypeDescription` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '设备类型描述',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_equipment_type_code`(`TypeCode` ASC) USING BTREE,
  INDEX `idx_type_name`(`TypeName` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9019 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'SMT设备类型字典' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_equipment_types
-- ----------------------------
INSERT INTO `smt_equipment_types` VALUES (9016, 'TAPI-ET-PR', '测试-印刷机类型', NULL, '2026-06-21 21:32:10.725', 'test', '2026-06-21 21:32:10.725', 'test', b'0', 1, NULL);
INSERT INTO `smt_equipment_types` VALUES (9017, 'TAPI-ET-SP', '测试-SPI类型', NULL, '2026-06-21 21:32:10.726', 'test', '2026-06-21 21:32:10.726', 'test', b'0', 1, NULL);
INSERT INTO `smt_equipment_types` VALUES (9018, 'TAPI-ET-RF', '测试-回流炉类型', NULL, '2026-06-21 21:32:10.730', 'test', '2026-06-21 21:32:10.730', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_functions
-- ----------------------------
DROP TABLE IF EXISTS `smt_functions`;
CREATE TABLE `smt_functions`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `FunctionCode` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '功能编码（英文，全局唯一，如 equipment, route, user）',
  `FunctionName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '功能名称（中文，用于界面显示，如\"设备管理\"\"工艺管理\"）',
  `Description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '功能描述',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  `Subsystem` tinyint NOT NULL COMMENT '所属子系统：1-MDM，2-RTM',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_function_code`(`FunctionCode` ASC) USING BTREE COMMENT '功能编码全局唯一'
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '功能模块表（系统可授权的功能模块定义）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_functions
-- ----------------------------
INSERT INTO `smt_functions` VALUES (1, 'WO_MANAGE', '工单管理', '查看工单列表，支持创建、释放、暂停、关闭工单，展示工单号、产品型号、计划数量、交货期、状态、分配产线信息', '2026-05-25 11:27:51.440', 'system', '2026-05-25 11:27:51.440', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (2, 'BATCH_MANAGE', '批次管理', '创建、删除、锁定批次，记录批次状态，展示批次计划数量、已完成数量、当前所在工序、预计完成时间', '2026-05-25 11:27:56.115', 'system', '2026-05-25 11:27:56.115', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (3, 'LINE_LOAD_MONITOR', '产线负载监控', '实时显示各产线的当前产能利用率、在制品数量、预计完工时间', '2026-05-25 11:28:00.076', 'system', '2026-05-25 11:28:00.076', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (4, 'SCHEDULE_BOARD', '排程看板', '以甘特图形式展示各产线/设备的工单排程，显示当前工单进度百分比', '2026-05-25 11:28:04.785', 'system', '2026-05-25 11:28:04.785', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (5, 'INBOUND_MANAGE', '进站管理', '按工艺路线校验批次进站权限，记录进站数量、选择设备、执行上料操作', '2026-05-25 11:28:09.764', 'system', '2026-05-25 11:28:09.764', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (6, 'LOADING_TASK_VIEW', '上料任务列表查看', '显示当前批次所需上料的站位物料清单，包含站位号、物料料号、规格、应上数量', '2026-05-25 11:28:14.710', 'system', '2026-05-25 11:28:14.710', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (7, 'INBOUND_LOADING_CHECK', '进站前上料校验', '扫描物料条码与站位码，系统自动校验物料是否与BOM一致', '2026-05-25 11:28:19.334', 'system', '2026-05-25 11:28:19.334', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (8, 'OUTBOUND_MANAGE', '出站管理', '记录出站时间、完工数量、不良数量，支持维修、报废、强制出站三种处置方式', '2026-05-25 11:28:25.756', 'system', '2026-05-25 11:28:25.756', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (9, 'REPAIR_MANAGE', '维修管理', '显示维修概览卡片，查看待维修批次列表，记录批次维修情况', '2026-05-25 11:28:30.420', 'system', '2026-05-25 11:28:30.420', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (10, 'QUALITY_JUDGE_INTERCEPT', '质量判定与拦截', '设置SPI、AOI检测数据阈值，批次直通率低于阈值时自动锁定该批次，禁止继续产出', '2026-05-25 11:28:34.575', 'system', '2026-05-25 11:28:34.575', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (11, 'PARAM_QUALITY_RELATE_QUERY', '参数质量关联查询', '输入批次号或时间范围，查看该批次的所有工艺参数记录与对应的SPI/AOI质量检测结果', '2026-05-25 11:28:38.579', 'system', '2026-05-25 11:28:38.579', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (12, 'LINE_STATUS_BOARD', '产线状态看板', '大屏展示当前生产工单、计划数量/已完成数量、完成率、设备状态', '2026-05-25 11:28:42.995', 'system', '2026-05-25 11:28:42.995', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (13, 'QUALITY_BOARD', '质量看板', '实时展示当天批次SPI直通率、AOI直通率、当天批次良率', '2026-05-25 11:28:47.427', 'system', '2026-05-25 11:28:47.427', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (14, 'PARAM_TEMPLATE_SELECT', '参数模板选择', '换线时根据当前工单的产品型号自动匹配对应的工艺参数模板', '2026-05-25 11:28:52.354', 'system', '2026-05-25 11:28:52.354', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (15, 'PARAM_ISSUE', '参数下发', '将参数模板下发至印刷机、回流炉、SPI、AOI设备，支持手动触发和自动下发', '2026-05-25 11:28:56.142', 'system', '2026-05-25 11:28:56.142', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (16, 'PARAM_CONSISTENCY_CHECK', '参数一致性校验', '读取设备实际参数与模板参数对比，差异超标则锁定设备并提示', '2026-05-25 11:29:00.627', 'system', '2026-05-25 11:29:00.627', 'system', b'0', 1, NULL, 2);
INSERT INTO `smt_functions` VALUES (17, 'PARAM_CONSISTENCY_CHECK是', '参数一致性校验是', '读取设备实际参数与模板参数对比，差异超标则锁定设备并提示', '2026-05-25 11:29:25.620', 'system', '2026-05-25 11:29:36.480', 'system', b'1', 3, NULL, 2);

-- ----------------------------
-- Table structure for smt_lines
-- ----------------------------
DROP TABLE IF EXISTS `smt_lines`;
CREATE TABLE `smt_lines`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LineCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产线编号（业务唯一）',
  `LineName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产线名称',
  `LineDescription` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '描述',
  `Workshop` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '所属车间',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_line_code`(`LineCode` ASC) USING BTREE,
  INDEX `idx_line_name`(`LineName` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'SMT产线主数据' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_lines
-- ----------------------------
INSERT INTO `smt_lines` VALUES (8, 'TAPI-LINE-01', '测试产线01', NULL, NULL, '2026-06-21 21:32:10.770', 'test', '2026-06-21 21:32:10.770', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_loading_records
-- ----------------------------
DROP TABLE IF EXISTS `smt_loading_records`;
CREATE TABLE `smt_loading_records`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `RouteStepId` bigint NOT NULL COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
  `EquipmentId` bigint NOT NULL COMMENT '设备ID（逻辑关联 smt_equipment.Id）',
  `MaterialId` bigint NOT NULL COMMENT '物料ID（逻辑关联 smt_materials.Id）',
  `OperatorId` bigint NOT NULL COMMENT '上料操作员ID（逻辑关联 smt_users.Id）',
  `LoadingTime` datetime NULL DEFAULT NULL COMMENT '上料时间',
  `ActualQuantity` int NULL DEFAULT NULL COMMENT '实际上料数量',
  `VerifyStatus` tinyint NOT NULL DEFAULT 0 COMMENT '校验结果: 0-未校验, 1-校验通过, 2-校验失败',
  `VerifyRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '校验失败原因',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  INDEX `idx_lot`(`LotId` ASC) USING BTREE,
  INDEX `idx_route_step`(`RouteStepId` ASC) USING BTREE,
  INDEX `idx_equipment`(`EquipmentId` ASC) USING BTREE,
  INDEX `idx_material`(`MaterialId` ASC) USING BTREE,
  INDEX `idx_operator`(`OperatorId` ASC) USING BTREE,
  CONSTRAINT `fk_loading_equipment` FOREIGN KEY (`EquipmentId`) REFERENCES `smt_equipment` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_material` FOREIGN KEY (`MaterialId`) REFERENCES `smt_materials` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_operator` FOREIGN KEY (`OperatorId`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_route_step` FOREIGN KEY (`RouteStepId`) REFERENCES `smt_route_steps` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '上料记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_loading_records
-- ----------------------------
INSERT INTO `smt_loading_records` VALUES (6, 29, 30, 11, 26, 11, '2026-06-21 21:38:16', 0, 2, NULL, '2026-06-21 21:38:16.080', 'system', '2026-06-21 21:38:16.080', 'system', b'0', 2, '状态改为生产中时自动创建默认上料记录');
INSERT INTO `smt_loading_records` VALUES (7, 29, 30, 11, 27, 11, '2026-06-21 21:38:16', 0, 2, NULL, '2026-06-21 21:38:16.080', 'system', '2026-06-21 21:38:16.080', 'system', b'0', 2, '状态改为生产中时自动创建默认上料记录');
INSERT INTO `smt_loading_records` VALUES (8, 29, 30, 11, 28, 11, '2026-06-21 21:38:16', 0, 2, NULL, '2026-06-21 21:38:16.080', 'system', '2026-06-21 21:38:16.080', 'system', b'0', 2, '状态改为生产中时自动创建默认上料记录');

-- ----------------------------
-- Table structure for smt_lot_operation_status
-- ----------------------------
DROP TABLE IF EXISTS `smt_lot_operation_status`;
CREATE TABLE `smt_lot_operation_status`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `RouteStepId` bigint NOT NULL COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '工序状态: 1-待进站, 2-已进站, 3-已出站, 4-暂停, 5-锁定, 6-跳过',
  `StationInTime` datetime NULL DEFAULT NULL COMMENT '进站时间',
  `StationInQuantity` int NULL DEFAULT NULL COMMENT '进站数量',
  `StationOutTime` datetime NULL DEFAULT NULL COMMENT '出站时间',
  `FinishedQuantity` int NULL DEFAULT NULL COMMENT '完工数量',
  `DefectQuantity` int NULL DEFAULT NULL COMMENT '不良数量',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_lot_route_step`(`LotId` ASC, `RouteStepId` ASC) USING BTREE,
  INDEX `idx_lot`(`LotId` ASC) USING BTREE,
  INDEX `idx_route_step`(`RouteStepId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  CONSTRAINT `fk_lot_op_status_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_lot_op_status_route_step` FOREIGN KEY (`RouteStepId`) REFERENCES `smt_route_steps` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_op_status` CHECK (`Status` between 1 and 6)
) ENGINE = InnoDB AUTO_INCREMENT = 23 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '批次工序状态表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_lot_operation_status
-- ----------------------------
INSERT INTO `smt_lot_operation_status` VALUES (22, 29, 30, 1, NULL, NULL, NULL, NULL, NULL, '2026-06-21 21:32:10.791', 'test', '2026-06-21 21:32:10.791', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_lots
-- ----------------------------
DROP TABLE IF EXISTS `smt_lots`;
CREATE TABLE `smt_lots`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '批次号（业务唯一）',
  `WorkOrderId` bigint NOT NULL COMMENT '所属工单ID（逻辑关联 smt_work_orders.Id）',
  `LineId` bigint NOT NULL COMMENT '所在产线ID（逻辑关联 smt_lines.Id）',
  `PlannedQuantity` int NOT NULL COMMENT '本批次计划生产数量',
  `CompletedQuantity` int NOT NULL DEFAULT 0 COMMENT '已完成数量',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '批次状态: 1-待生产, 2-生产中, 3-暂停, 4-维修中, 5-已锁定, 6-已完成',
  `EstimatedCompletionTime` datetime NULL DEFAULT NULL COMMENT '预计完成时间',
  `StartTime` datetime NULL DEFAULT NULL COMMENT '上线时间（进入第一道工序）',
  `EndTime` datetime NULL DEFAULT NULL COMMENT '下线时间（完成最后一道工序）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_lot_code`(`LotCode` ASC) USING BTREE,
  INDEX `idx_work_order`(`WorkOrderId` ASC) USING BTREE,
  INDEX `idx_line`(`LineId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  CONSTRAINT `fk_lot_line` FOREIGN KEY (`LineId`) REFERENCES `smt_lines` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_lot_work_order` FOREIGN KEY (`WorkOrderId`) REFERENCES `smt_work_orders` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '批次表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_lots
-- ----------------------------
INSERT INTO `smt_lots` VALUES (29, 'TAPI-LOT-001', 44, 8, 1000, 0, 2, NULL, NULL, NULL, '2026-06-21 21:32:10.789', 'test', '2026-06-21 21:38:16.080', 'system', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_material_substitutes
-- ----------------------------
DROP TABLE IF EXISTS `smt_material_substitutes`;
CREATE TABLE `smt_material_substitutes`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `MaterialId` bigint NOT NULL COMMENT '主料ID（逻辑关联 smt_materials.Id）',
  `SubstituteMaterialId` bigint NOT NULL COMMENT '替代料ID（逻辑关联 smt_materials.Id）',
  `Direction` tinyint NOT NULL DEFAULT 1 COMMENT '替代方向: 1-单向, 2-双向',
  `Priority` int NOT NULL DEFAULT 1 COMMENT '优先级（数字越小越优先）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_substitute`(`MaterialId` ASC, `SubstituteMaterialId` ASC) USING BTREE COMMENT '同一主料与替代料关系唯一',
  INDEX `idx_material`(`MaterialId` ASC) USING BTREE,
  INDEX `idx_substitute_material`(`SubstituteMaterialId` ASC) USING BTREE,
  CONSTRAINT `fk_substitute_material` FOREIGN KEY (`MaterialId`) REFERENCES `smt_materials` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_substitute_substitute_material` FOREIGN KEY (`SubstituteMaterialId`) REFERENCES `smt_materials` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '替代料关系表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_material_substitutes
-- ----------------------------

-- ----------------------------
-- Table structure for smt_material_types
-- ----------------------------
DROP TABLE IF EXISTS `smt_material_types`;
CREATE TABLE `smt_material_types`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TypeCode` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料类型编码（唯一）',
  `TypeName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料类型名称',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_material_type_code`(`TypeCode` ASC) USING BTREE,
  INDEX `idx_type_name`(`TypeName` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '物料类型字典' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_material_types
-- ----------------------------
INSERT INTO `smt_material_types` VALUES (15, 'TAPI-MT', '测试SMD元件', '2026-06-21 21:32:10.757', 'test', '2026-06-21 21:32:10.757', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_materials
-- ----------------------------
DROP TABLE IF EXISTS `smt_materials`;
CREATE TABLE `smt_materials`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `MaterialCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '元件料号（业务唯一）',
  `MaterialDesc` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料描述',
  `MaterialTypeId` bigint NOT NULL COMMENT '物料类型ID（逻辑关联 smt_material_types.Id）',
  `PackageType` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '封装类型',
  `Brand` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '品牌',
  `MinPackQty` int NULL DEFAULT NULL COMMENT '最小包装量',
  `StorageCondition` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '存储条件',
  `MSDLevel` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'MSD湿度敏感等级',
  `MaterialBarcode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '物料条码（业务唯一），用于扫码上料等场景快速识别物料',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_material_code`(`MaterialCode` ASC) USING BTREE,
  UNIQUE INDEX `uq_material_barcode`(`MaterialBarcode` ASC) USING BTREE COMMENT '物料条码全局唯一',
  INDEX `idx_material_type`(`MaterialTypeId` ASC) USING BTREE,
  INDEX `idx_material_desc`(`MaterialDesc` ASC) USING BTREE,
  CONSTRAINT `fk_material_material_type` FOREIGN KEY (`MaterialTypeId`) REFERENCES `smt_material_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '物料主数据' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_materials
-- ----------------------------
INSERT INTO `smt_materials` VALUES (26, 'TAPI-MAT-0201', '测试0201电阻', 15, '0201', 'T-BRAND', 10000, NULL, NULL, NULL, '2026-06-21 21:32:10.759', 'test', '2026-06-21 21:32:10.759', 'test', b'0', 1, NULL);
INSERT INTO `smt_materials` VALUES (27, 'TAPI-MAT-0402', '测试0402电容', 15, '0402', 'T-BRAND', 5000, NULL, NULL, NULL, '2026-06-21 21:32:10.761', 'test', '2026-06-21 21:32:10.761', 'test', b'0', 1, NULL);
INSERT INTO `smt_materials` VALUES (28, 'TAPI-MAT-QFP', '测试QFP芯片', 15, 'QFP', 'T-BRAND', 500, NULL, NULL, NULL, '2026-06-21 21:32:10.762', 'test', '2026-06-21 21:32:10.762', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_operations
-- ----------------------------
DROP TABLE IF EXISTS `smt_operations`;
CREATE TABLE `smt_operations`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `OperationCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工序代码（业务唯一，如 PRINTER, SPI, REFLOW, AOI）',
  `OperationName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工序名称（如\"锡膏印刷\"\"SPI检测\"\"回流焊接\"）',
  `Description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '工序描述/补充说明',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人（工艺工程师账号）',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_operation_code`(`OperationCode` ASC) USING BTREE COMMENT '工序代码全局唯一',
  INDEX `idx_operation_name`(`OperationName` ASC) USING BTREE COMMENT '按工序名称模糊查询'
) ENGINE = InnoDB AUTO_INCREMENT = 35 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工序字典表（SMT工序标准定义）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_operations
-- ----------------------------
INSERT INTO `smt_operations` VALUES (32, 'TAPI-PRINTER', '测试-锡膏印刷', '测试工序', '2026-06-21 21:32:10.717', 'test', '2026-06-21 21:32:10.717', 'test', b'0', 1, NULL);
INSERT INTO `smt_operations` VALUES (33, 'TAPI-SPI', '测试-SPI检测', '测试工序', '2026-06-21 21:32:10.719', 'test', '2026-06-21 21:32:10.719', 'test', b'0', 1, NULL);
INSERT INTO `smt_operations` VALUES (34, 'TAPI-REFLOW', '测试-回流焊接', '测试工序', '2026-06-21 21:32:10.722', 'test', '2026-06-21 21:32:10.722', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_parameter_items
-- ----------------------------
DROP TABLE IF EXISTS `smt_parameter_items`;
CREATE TABLE `smt_parameter_items`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TemplateId` bigint NOT NULL COMMENT '所属模板ID（逻辑关联 smt_parameter_templates.Id）',
  `ParameterName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '参数名称',
  `ParameterValue` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '设定值',
  `MinLimit` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '下限值',
  `MaxLimit` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '上限值',
  `Unit` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '单位',
  `Sequence` int NULL DEFAULT NULL COMMENT '显示顺序号（用于数据库查询排序和前端页面有序展示，非必填，NULL 表示不排序）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_template_parameter`(`TemplateId` ASC, `ParameterName` ASC) USING BTREE,
  INDEX `idx_template`(`TemplateId` ASC) USING BTREE,
  CONSTRAINT `fk_param_item_template` FOREIGN KEY (`TemplateId`) REFERENCES `smt_parameter_templates` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '参数项明细表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_parameter_items
-- ----------------------------

-- ----------------------------
-- Table structure for smt_parameter_templates
-- ----------------------------
DROP TABLE IF EXISTS `smt_parameter_templates`;
CREATE TABLE `smt_parameter_templates`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TemplateCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码（业务唯一）',
  `TemplateName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板名称',
  `EquipmentTypeId` bigint NOT NULL COMMENT '适用设备类型ID（逻辑关联 smt_equipment_types.Id）',
  `Version` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '版本号',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '状态: 1-启用, 0-停用',
  `EffectiveDate` date NULL DEFAULT NULL COMMENT '生效日期（模板从该日期起可用，NULL表示创建即生效）',
  `ExpiryDate` date NULL DEFAULT NULL COMMENT '失效日期（模板到期自动停用，NULL表示永久有效）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_template_code`(`TemplateCode` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  CONSTRAINT `fk_param_template_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工艺参数模板主表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_parameter_templates
-- ----------------------------
INSERT INTO `smt_parameter_templates` VALUES (17, 'TAPI-PARAM-PR', '印刷机测试参数', 9016, 'V1.0', 1, NULL, NULL, '2026-06-21 21:32:10.741', 'test', '2026-06-21 21:32:10.741', 'test', b'0', 1, NULL);
INSERT INTO `smt_parameter_templates` VALUES (18, 'TAPI-PARAM-SP', 'SPI测试参数', 9017, 'V1.0', 1, NULL, NULL, '2026-06-21 21:32:10.743', 'test', '2026-06-21 21:32:10.743', 'test', b'0', 1, NULL);
INSERT INTO `smt_parameter_templates` VALUES (19, 'TAPI-PARAM-RF', '回流炉测试参数', 9018, 'V1.0', 1, NULL, NULL, '2026-06-21 21:32:10.746', 'test', '2026-06-21 21:32:10.746', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_product_types
-- ----------------------------
DROP TABLE IF EXISTS `smt_product_types`;
CREATE TABLE `smt_product_types`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TypeCode` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产品类型编码',
  `TypeName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产品类型名称',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_product_type_code`(`TypeCode` ASC) USING BTREE,
  INDEX `idx_type_name`(`TypeName` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '产品类型字典' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_product_types
-- ----------------------------
INSERT INTO `smt_product_types` VALUES (11, 'TAPI-PT', '测试主板类型', '2026-06-21 21:32:10.709', 'test', '2026-06-21 21:32:10.709', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_products
-- ----------------------------
DROP TABLE IF EXISTS `smt_products`;
CREATE TABLE `smt_products`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `ProductCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产品编码（业务唯一）',
  `ProductName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产品名称',
  `Model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '产品型号',
  `Version` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '设计版本',
  `PCBDimensions` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'PCB尺寸（如 100x80mm）',
  `PCBThickness` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'PCB厚度（如 1.6mm）',
  `PanelCount` int NULL DEFAULT NULL COMMENT '拼板数量',
  `ProductTypeId` bigint NOT NULL COMMENT '产品类型ID（逻辑关联 smt_product_types.Id）',
  `SpiThreshold` decimal(5, 2) NULL DEFAULT NULL COMMENT 'SPI检测直通率阈值（如95.00），由工艺配置师设置',
  `AoiThreshold` decimal(5, 2) NULL DEFAULT NULL COMMENT 'AOI检测直通率阈值（如95.00），由工艺配置师设置',
  `DefaultRouteId` bigint NULL DEFAULT NULL COMMENT '默认工艺路线ID（逻辑关联 smt_routes.Id），产品投产时如未指定路线则使用此默认值',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_product_code`(`ProductCode` ASC) USING BTREE,
  INDEX `idx_product_type`(`ProductTypeId` ASC) USING BTREE,
  INDEX `idx_product_name`(`ProductName` ASC) USING BTREE,
  INDEX `idx_default_route`(`DefaultRouteId` ASC) USING BTREE COMMENT '按默认工艺路线查询产品',
  CONSTRAINT `fk_product_product_type` FOREIGN KEY (`ProductTypeId`) REFERENCES `smt_product_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_aoi_threshold` CHECK (`AoiThreshold` between 0 and 100),
  CONSTRAINT `chk_spi_threshold` CHECK (`SpiThreshold` between 0 and 100)
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '产品主数据' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_products
-- ----------------------------
INSERT INTO `smt_products` VALUES (12, 'TAPI-PROD-001', '测试手机主板', 'TEST-A', 'V1.0', '100x80mm', NULL, 10, 11, 95.00, 95.00, 9, '2026-06-21 21:32:10.715', 'test', '2026-06-21 21:32:10.715', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_repair_records
-- ----------------------------
DROP TABLE IF EXISTS `smt_repair_records`;
CREATE TABLE `smt_repair_records`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `RouteStepId` bigint NOT NULL COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id；维修发生在该工序，维修完成后批次回到此工序重新进站）',
  `Status` tinyint NOT NULL DEFAULT 0 COMMENT '维修状态: 0-待维修, 1-维修中, 2-已完成',
  `RepairQuantity` int NOT NULL COMMENT '送修数量',
  `RepairedQuantity` int NULL DEFAULT NULL COMMENT '已修复数量',
  `ScrapQuantity` int NULL DEFAULT NULL COMMENT '维修中报废数量',
  `RepairDescription` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '故障原因及维修措施',
  `RepairResult` tinyint NULL DEFAULT NULL COMMENT '维修结果: 1-已修复, 2-报废',
  `RepairBy` bigint NULL DEFAULT NULL COMMENT '维修操作员ID（逻辑关联 smt_users.Id）',
  `RepairStartTime` datetime NULL DEFAULT NULL COMMENT '维修开始时间',
  `RepairEndTime` datetime NULL DEFAULT NULL COMMENT '维修结束时间',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  INDEX `idx_lot`(`LotId` ASC) USING BTREE,
  INDEX `idx_route_step`(`RouteStepId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  INDEX `idx_repair_by`(`RepairBy` ASC) USING BTREE,
  CONSTRAINT `fk_repair_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_repair_operator` FOREIGN KEY (`RepairBy`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_repair_route_step` FOREIGN KEY (`RouteStepId`) REFERENCES `smt_route_steps` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '维修记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_repair_records
-- ----------------------------

-- ----------------------------
-- Table structure for smt_role_functions
-- ----------------------------
DROP TABLE IF EXISTS `smt_role_functions`;
CREATE TABLE `smt_role_functions`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `RoleId` bigint NOT NULL COMMENT '角色ID（逻辑关联 smt_roles.Id）',
  `FunctionId` bigint NOT NULL COMMENT '功能模块ID（逻辑关联 smt_functions.Id）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_role_function`(`RoleId` ASC, `FunctionId` ASC) USING BTREE COMMENT '同一角色对同一功能模块只关联一次',
  INDEX `idx_role`(`RoleId` ASC) USING BTREE COMMENT '按角色查询其功能模块',
  INDEX `idx_function`(`FunctionId` ASC) USING BTREE COMMENT '按功能模块查询被哪些角色拥有',
  CONSTRAINT `fk_role_function_function` FOREIGN KEY (`FunctionId`) REFERENCES `smt_functions` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_role_function_role` FOREIGN KEY (`RoleId`) REFERENCES `smt_roles` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色-功能关联表（角色与功能模块的多对多关系）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_role_functions
-- ----------------------------
INSERT INTO `smt_role_functions` VALUES (1, 4, 1, '2026-05-25 11:33:22.196', 'system', '2026-05-25 11:33:22.196', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (2, 4, 2, '2026-05-25 11:33:26.458', 'system', '2026-05-25 11:33:26.458', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (3, 4, 3, '2026-05-25 11:33:30.668', 'system', '2026-05-25 11:33:30.668', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (4, 4, 4, '2026-05-25 11:33:41.037', 'system', '2026-05-25 11:33:41.037', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (5, 1, 5, '2026-05-25 11:33:45.590', 'system', '2026-05-25 11:33:45.590', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (6, 1, 6, '2026-05-25 11:33:50.760', 'system', '2026-05-25 11:33:50.760', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (7, 1, 7, '2026-05-25 11:33:57.025', 'system', '2026-05-25 11:33:57.025', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (8, 1, 8, '2026-05-25 11:34:01.518', 'system', '2026-05-25 11:34:01.518', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (9, 1, 9, '2026-05-25 11:34:05.729', 'system', '2026-05-25 11:34:05.729', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (10, 3, 10, '2026-05-25 11:34:11.223', 'system', '2026-05-25 11:34:11.223', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (11, 3, 11, '2026-05-25 11:34:17.421', 'system', '2026-05-25 11:34:17.421', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (12, 2, 12, '2026-05-25 11:34:21.773', 'system', '2026-05-25 11:34:21.773', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (13, 2, 13, '2026-05-25 11:34:27.090', 'system', '2026-05-25 11:34:27.090', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (14, 2, 14, '2026-05-25 11:34:33.652', 'system', '2026-05-25 11:34:33.652', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (15, 2, 15, '2026-05-25 11:34:37.821', 'system', '2026-05-25 11:34:37.821', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (16, 2, 16, '2026-05-25 11:34:52.158', 'system', '2026-05-25 11:34:52.158', 'system', b'0', 1, NULL);
INSERT INTO `smt_role_functions` VALUES (17, 2, 3, '2026-05-25 11:35:07.445', 'system', '2026-05-25 11:35:29.541', 'system', b'1', 3, NULL);

-- ----------------------------
-- Table structure for smt_roles
-- ----------------------------
DROP TABLE IF EXISTS `smt_roles`;
CREATE TABLE `smt_roles`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `RoleCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色编码（英文，业务唯一，如 OPERATOR, ENGINEER, ADMIN）',
  `RoleName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色名称（中文，如\"操作工\"\"工艺工程师\"）',
  `Description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '角色说明，描述该角色拥有的权限范围',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人（系统管理员）',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_role_code`(`RoleCode` ASC) USING BTREE COMMENT '角色编码全局唯一，避免重复创建'
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色表（系统角色的定义）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_roles
-- ----------------------------
INSERT INTO `smt_roles` VALUES (1, 'RTM_OPERATOR', 'RTM操作员', '负责SMT车间MES-RTM系统现场生产执行操作，完成批次进站/出站登记、物料扫码上料与防错校验、不良品维修/报废/强制出站处置，按工序完成生产操作数据录入', '2026-05-25 11:02:50.610', 'system', '2026-05-25 11:02:50.610', 'system', b'0', 1, NULL);
INSERT INTO `smt_roles` VALUES (2, 'RTM_ADMIN', 'RTM管理员', '负责MES-RTM实时制造执行子系统权限配置、系统运行维护，统筹RTM端功能权限分配，保障实时制造执行子系统正常使用与数据协同', '2026-05-25 11:03:05.713', 'system', '2026-05-25 11:03:05.713', 'system', b'0', 1, NULL);
INSERT INTO `smt_roles` VALUES (3, 'QUALITY_ENGINEER', '质量工程师', '负责MES-RTM系统质量管理，设置SPI/AOI检测阈值、批次直通率判定规则，对异常批次自动锁定拦截，开展参数-质量关联追溯查询、维修批次管控', '2026-05-25 11:03:10.827', 'system', '2026-05-25 11:03:10.827', 'system', b'0', 1, NULL);
INSERT INTO `smt_roles` VALUES (4, 'PRODUCTION_SUPERVISOR', '生产主管', '负责MES-RTM系统生产调度与工单管理，完成工单创建/释放/暂停/关闭、批次生成与状态管控、产线负载监控、排程调度，统筹产线生产执行与工单收尾', '2026-05-25 11:03:17.424', 'system', '2026-05-25 11:03:17.424', 'system', b'0', 1, NULL);
INSERT INTO `smt_roles` VALUES (6, 'PRODUCTION_SUPERVISO是R', '生产主管啊', '负责MES-RTM系统生产调度与工单管理，完成工单创建/释放/暂停/关闭、批次生成与状态管控、产线负载监控、排程调度，统筹产线生产执行与工单收尾', '2026-05-25 11:03:33.167', 'system', '2026-05-25 11:05:46.843', 'system', b'1', 3, NULL);
INSERT INTO `smt_roles` VALUES (7, 'LEADER', '班组长', '产线班组长角色', '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);
INSERT INTO `smt_roles` VALUES (8, 'OPERATOR', '操作工', '产线操作工角色', '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_route_steps
-- ----------------------------
DROP TABLE IF EXISTS `smt_route_steps`;
CREATE TABLE `smt_route_steps`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `RouteId` bigint NOT NULL COMMENT '工艺路线ID（逻辑关联 smt_routes.Id）',
  `OperationId` bigint NOT NULL COMMENT '工序ID（逻辑关联 smt_operations.Id）',
  `Sequence` int NOT NULL COMMENT '工序序号（10,20,30...）',
  `EquipmentTypeId` bigint NOT NULL COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id），生产时据此校验设备类型',
  `ParameterTemplateId` bigint NOT NULL COMMENT '参数模板ID（逻辑关联 smt_parameter_templates.Id），定义该工序到此路线的工艺参数',
  `StandardTime` int NULL DEFAULT NULL COMMENT '标准工时（秒），此工序在该工艺路线中的标准作业时间，用于估算批次完工时间和产线产能',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_route_operation`(`RouteId` ASC, `OperationId` ASC) USING BTREE,
  UNIQUE INDEX `uq_route_sequence`(`RouteId` ASC, `Sequence` ASC) USING BTREE,
  INDEX `idx_operation`(`OperationId` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  INDEX `idx_parameter_template`(`ParameterTemplateId` ASC) USING BTREE,
  CONSTRAINT `fk_route_step_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_route_step_operation` FOREIGN KEY (`OperationId`) REFERENCES `smt_operations` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_route_step_route` FOREIGN KEY (`RouteId`) REFERENCES `smt_routes` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 33 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工艺路线工序关系表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_route_steps
-- ----------------------------
INSERT INTO `smt_route_steps` VALUES (30, 9, 32, 10, 9016, 17, 60, '2026-06-21 21:32:10.748', 'test', '2026-06-21 21:32:10.748', 'test', b'0', 1, NULL);
INSERT INTO `smt_route_steps` VALUES (31, 9, 33, 20, 9017, 18, 30, '2026-06-21 21:32:10.752', 'test', '2026-06-21 21:32:10.752', 'test', b'0', 1, NULL);
INSERT INTO `smt_route_steps` VALUES (32, 9, 34, 30, 9018, 19, 90, '2026-06-21 21:32:10.755', 'test', '2026-06-21 21:32:10.755', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_routes
-- ----------------------------
DROP TABLE IF EXISTS `smt_routes`;
CREATE TABLE `smt_routes`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `RouteCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '路线编码（业务唯一，如 ROUTE-PCB-STD）',
  `RouteName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '路线名称（如\"手机主板标准工艺\"）',
  `ProductTypeId` bigint NOT NULL COMMENT '适用产品类型ID（逻辑关联 smt_product_types.Id，决定哪些产品可选用此路线）',
  `Description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '路线描述/备注',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '状态: 1-创建(不可用), 2-发布(可用), 3-停用(不可用)',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人（工艺工程师账号）',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注（可记录变更原因）',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_route_code`(`RouteCode` ASC) USING BTREE COMMENT '路线编码全局唯一',
  INDEX `idx_product_type`(`ProductTypeId` ASC) USING BTREE COMMENT '按适用产品类型查询',
  INDEX `idx_status`(`Status` ASC) USING BTREE COMMENT '按状态筛选(创建/发布/停用)',
  CONSTRAINT `fk_route_product_type` FOREIGN KEY (`ProductTypeId`) REFERENCES `smt_product_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_route_status` CHECK (`Status` between 1 and 3)
) ENGINE = InnoDB AUTO_INCREMENT = 10 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工艺路线主表（SMT工艺路线定义）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_routes
-- ----------------------------
INSERT INTO `smt_routes` VALUES (9, 'TAPI-ROUTE', '测试PCB标准工艺', 11, NULL, 2, '2026-06-21 21:32:10.713', 'test', '2026-06-21 21:32:10.713', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_station_in_records
-- ----------------------------
DROP TABLE IF EXISTS `smt_station_in_records`;
CREATE TABLE `smt_station_in_records`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `RouteStepId` bigint NOT NULL COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
  `Round` int NOT NULL DEFAULT 1 COMMENT '进站轮次（同一批次在同一道工序的进站序号，从1开始递增；第1次进站=1，维修后重新进站=2...）',
  `EquipmentId` bigint NULL DEFAULT NULL COMMENT '所选设备ID（逻辑关联 smt_equipment.Id）',
  `OperatorId` bigint NOT NULL COMMENT '进站操作员ID（逻辑关联 smt_users.Id）',
  `StationInTime` datetime NULL DEFAULT NULL COMMENT '进站时间',
  `StationInQuantity` int NULL DEFAULT NULL COMMENT '进站数量',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '进站状态: 1-校验通过, 2-校验失败',
  `VerifyRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '校验失败原因',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_lot_step_round`(`LotId` ASC, `RouteStepId` ASC, `Round` ASC) USING BTREE,
  INDEX `idx_lot`(`LotId` ASC) USING BTREE,
  INDEX `idx_route_step`(`RouteStepId` ASC) USING BTREE,
  INDEX `idx_equipment`(`EquipmentId` ASC) USING BTREE,
  INDEX `idx_operator`(`OperatorId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  CONSTRAINT `fk_station_in_equipment` FOREIGN KEY (`EquipmentId`) REFERENCES `smt_equipment` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_station_in_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_station_in_operator` FOREIGN KEY (`OperatorId`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_station_in_route_step` FOREIGN KEY (`RouteStepId`) REFERENCES `smt_route_steps` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_station_in_status` CHECK (`Status` between 1 and 2)
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '进站记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_station_in_records
-- ----------------------------

-- ----------------------------
-- Table structure for smt_station_out_records
-- ----------------------------
DROP TABLE IF EXISTS `smt_station_out_records`;
CREATE TABLE `smt_station_out_records`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `RouteStepId` bigint NOT NULL COMMENT '工序步骤ID（冗余，逻辑关联 smt_route_steps.Id）',
  `Round` int NOT NULL DEFAULT 1 COMMENT '出站轮次（与进站记录表的 Round 对应，标识属于第几轮进出站；默认第1轮）',
  `OperatorId` bigint NOT NULL COMMENT '出站操作员ID（逻辑关联 smt_users.Id）',
  `StationOutTime` datetime NULL DEFAULT NULL COMMENT '出站时间',
  `FinishedQuantity` int NULL DEFAULT NULL COMMENT '完工数量',
  `DefectQuantity` int NULL DEFAULT NULL COMMENT '不良数量',
  `IsNormal` bit(1) NOT NULL DEFAULT b'1' COMMENT '出站类型: 1-正常出站, 0-异常出站',
  `DisposalType` tinyint NULL DEFAULT NULL COMMENT '不良处置: 1-维修, 2-报废, 3-强制出站（IsNormal=0时必填）',
  `DisposalRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '处置原因（强制出站时必填）',
  `SpiPassRate` decimal(5, 2) NULL DEFAULT NULL COMMENT 'SPI检测直通率百分比（SPI工序出站时填写，与产品SPI阈值比对）',
  `AoiPassRate` decimal(5, 2) NULL DEFAULT NULL COMMENT 'AOI检测直通率百分比（AOI工序出站时填写，与产品AOI阈值比对）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_lot_step_round`(`LotId` ASC, `RouteStepId` ASC, `Round` ASC) USING BTREE,
  INDEX `idx_lot`(`LotId` ASC) USING BTREE,
  INDEX `idx_route_step`(`RouteStepId` ASC) USING BTREE,
  INDEX `idx_operator`(`OperatorId` ASC) USING BTREE,
  CONSTRAINT `fk_station_out_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_station_out_operator` FOREIGN KEY (`OperatorId`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_station_out_route_step` FOREIGN KEY (`RouteStepId`) REFERENCES `smt_route_steps` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_aoi_pass_rate` CHECK (`AoiPassRate` between 0 and 100),
  CONSTRAINT `chk_spi_pass_rate` CHECK (`SpiPassRate` between 0 and 100)
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '出站记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_station_out_records
-- ----------------------------

-- ----------------------------
-- Table structure for smt_unloading_records
-- ----------------------------
DROP TABLE IF EXISTS `smt_unloading_records`;
CREATE TABLE `smt_unloading_records`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LoadingRecordId` bigint NOT NULL COMMENT '关联上料记录ID（逻辑关联 smt_loading_records.Id），明确下料对应哪次上料',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `RouteStepId` bigint NOT NULL COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
  `EquipmentId` bigint NOT NULL COMMENT '设备ID（逻辑关联 smt_equipment.Id）',
  `MaterialId` bigint NOT NULL COMMENT '物料ID（逻辑关联 smt_materials.Id）',
  `UnloadingTime` datetime NULL DEFAULT NULL COMMENT '下料时间',
  `OperatorId` bigint NOT NULL COMMENT '下料操作员ID（逻辑关联 smt_users.Id）',
  `Reason` tinyint NULL DEFAULT NULL COMMENT '下料原因: 1-批次完工换线, 2-物料耗尽, 3-品质异常, 4-其他',
  `UnloadQuantity` int NULL DEFAULT NULL COMMENT '下料数量（支持部分下料，卸下数量可小于剩余数量）',
  `InitialQuantity` int NULL DEFAULT NULL COMMENT '初始上料数量（从关联的上料记录获取）',
  `ActualUsedQuantity` int NULL DEFAULT NULL COMMENT '实际使用数量（本次生产中实际消耗的物料数量）',
  `RemainQuantity` int NULL DEFAULT NULL COMMENT '剩余数量（下料时物料的实际剩余量）',
  `WastageQuantity` int NULL DEFAULT NULL COMMENT '损耗数量（因抛料/不良等原因造成的损耗）',
  `Remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '下料备注',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  INDEX `idx_loading_record`(`LoadingRecordId` ASC) USING BTREE,
  INDEX `idx_lot`(`LotId` ASC) USING BTREE,
  INDEX `idx_route_step`(`RouteStepId` ASC) USING BTREE,
  INDEX `idx_equipment`(`EquipmentId` ASC) USING BTREE,
  INDEX `idx_material`(`MaterialId` ASC) USING BTREE,
  INDEX `idx_operator`(`OperatorId` ASC) USING BTREE,
  CONSTRAINT `fk_unloading_equipment` FOREIGN KEY (`EquipmentId`) REFERENCES `smt_equipment` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_unloading_loading_record` FOREIGN KEY (`LoadingRecordId`) REFERENCES `smt_loading_records` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_unloading_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_unloading_material` FOREIGN KEY (`MaterialId`) REFERENCES `smt_materials` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_unloading_operator` FOREIGN KEY (`OperatorId`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_unloading_route_step` FOREIGN KEY (`RouteStepId`) REFERENCES `smt_route_steps` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_unloading_quantity` CHECK ((`RemainQuantity` is null) or (`RemainQuantity` >= 0))
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '下料记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_unloading_records
-- ----------------------------

-- ----------------------------
-- Table structure for smt_user_roles
-- ----------------------------
DROP TABLE IF EXISTS `smt_user_roles`;
CREATE TABLE `smt_user_roles`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `UserId` bigint NOT NULL COMMENT '用户ID（逻辑关联 smt_users.Id）',
  `RoleId` bigint NOT NULL COMMENT '角色ID（逻辑关联 smt_roles.Id）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人（分配权限的操作人，通常为系统管理员）',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除（解除关联）',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_user_role`(`UserId` ASC, `RoleId` ASC) USING BTREE COMMENT '同一用户对同一角色只能关联一次',
  INDEX `idx_user`(`UserId` ASC) USING BTREE COMMENT '按用户查询其拥有的角色',
  INDEX `idx_role`(`RoleId` ASC) USING BTREE COMMENT '按角色查询其下用户',
  CONSTRAINT `fk_user_role_role` FOREIGN KEY (`RoleId`) REFERENCES `smt_roles` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_user_role_user` FOREIGN KEY (`UserId`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 14 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户-角色关联表（用户与角色的多对多关系）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_user_roles
-- ----------------------------
INSERT INTO `smt_user_roles` VALUES (1, 1, 1, '2026-05-25 11:42:26.188', 'system', '2026-05-25 11:42:26.188', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (2, 1, 2, '2026-05-25 11:42:30.017', 'system', '2026-05-25 11:42:30.017', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (3, 2, 2, '2026-05-25 11:42:33.991', 'system', '2026-05-25 11:42:33.991', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (4, 2, 3, '2026-05-25 11:42:38.604', 'system', '2026-05-25 11:42:38.604', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (5, 3, 3, '2026-05-25 11:42:43.449', 'system', '2026-05-25 11:42:43.449', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (6, 3, 4, '2026-05-25 11:42:47.346', 'system', '2026-05-25 11:42:47.346', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (7, 4, 4, '2026-05-25 11:42:52.162', 'system', '2026-05-25 11:42:52.162', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (8, 4, 3, '2026-05-25 11:43:59.673', 'system', '2026-05-25 11:44:18.395', 'system', b'1', 3, NULL);
INSERT INTO `smt_user_roles` VALUES (9, 6, 8, '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (10, 7, 8, '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (11, 8, 7, '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (12, 9, 7, '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);
INSERT INTO `smt_user_roles` VALUES (13, 9, 8, '2026-06-21 17:17:50.000', 'system', '2026-06-21 17:17:50.000', 'system', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_users
-- ----------------------------
DROP TABLE IF EXISTS `smt_users`;
CREATE TABLE `smt_users`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `Username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户账号（登录名，全局唯一）',
  `PasswordHash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '密码哈希值，存储加密后的密码',
  `FullName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '用户真实姓名，用于界面显示和操作记录展示',
  `Department` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '所属部门（如SMT车间、工艺部、质量部），部门未单独建模',
  `Position` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '岗位（如操作工、班组长、工艺工程师）',
  `Contact` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '联系方式（电话/邮箱等）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人（通常为系统管理员账号）',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注（如重置密码、离职禁用等）',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_username`(`Username` ASC) USING BTREE COMMENT '登录账号全局唯一，防止重复注册'
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统用户表（MES所有登录用户的基础信息）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_users
-- ----------------------------
INSERT INTO `smt_users` VALUES (11, 'tapi-operator', 'hash123', '测试操作员', 'SMT车间', '操作工', NULL, '2026-06-21 21:32:10.777', 'test', '2026-06-21 21:32:10.777', 'test', b'0', 1, NULL);

-- ----------------------------
-- Table structure for smt_work_orders
-- ----------------------------
DROP TABLE IF EXISTS `smt_work_orders`;
CREATE TABLE `smt_work_orders`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `WorkOrderCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工单号（日期+流水号，业务唯一）',
  `ProductId` bigint NOT NULL COMMENT '产品ID（逻辑关联 smt_products.Id）',
  `RouteId` bigint NOT NULL COMMENT '工艺路线ID（逻辑关联 smt_routes.Id）',
  `PlannedQuantity` int NOT NULL COMMENT '计划生产数量',
  `DueDate` datetime NULL DEFAULT NULL COMMENT '交货期限',
  `Status` tinyint NOT NULL DEFAULT 1 COMMENT '工单状态: 1-草稿, 2-已释放, 3-生产中, 4-已暂停, 5-已完成, 6-已关闭',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_work_order_code`(`WorkOrderCode` ASC) USING BTREE,
  INDEX `idx_product`(`ProductId` ASC) USING BTREE,
  INDEX `idx_route`(`RouteId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  CONSTRAINT `fk_work_order_product` FOREIGN KEY (`ProductId`) REFERENCES `smt_products` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_work_order_route` FOREIGN KEY (`RouteId`) REFERENCES `smt_routes` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 45 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of smt_work_orders
-- ----------------------------
INSERT INTO `smt_work_orders` VALUES (44, 'TAPI-WO-001', 12, 9, 1000, '2026-06-28 21:32:10', 2, '2026-06-21 21:32:10.787', 'test', '2026-06-21 21:32:10.787', 'test', b'0', 1, NULL);

SET FOREIGN_KEY_CHECKS = 1;
