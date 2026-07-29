/*
 Navicat Premium Data Transfer

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : smt_mes

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 27/07/2026 16:42:50
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
) ENGINE = InnoDB AUTO_INCREMENT = 19 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'BOM版本头表' ROW_FORMAT = DYNAMIC;

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
  `PackageTypeId` bigint NOT NULL COMMENT '封装类型ID（逻辑关联 smt_package_types.Id，从物料继承）',
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
  INDEX `idx_package_type`(`PackageTypeId` ASC) USING BTREE,
  CONSTRAINT `fk_bom_item_bom` FOREIGN KEY (`BomId`) REFERENCES `smt_bom` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_bom_item_material` FOREIGN KEY (`MaterialId`) REFERENCES `smt_materials` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_bom_item_package_type` FOREIGN KEY (`PackageTypeId`) REFERENCES `smt_package_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 66 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'BOM行项' ROW_FORMAT = DYNAMIC;

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
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  INDEX `idx_equipment_name`(`EquipmentName` ASC) USING BTREE,
  CONSTRAINT `fk_equipment_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_equipment_status` CHECK (`Status` between 1 and 6)
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'SMT设备档案' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_equipment_package_types
-- ----------------------------
DROP TABLE IF EXISTS `smt_equipment_package_types`;
CREATE TABLE `smt_equipment_package_types`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `EquipmentTypeId` bigint NOT NULL COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id）',
  `PackageTypeId` bigint NOT NULL COMMENT '封装类型ID（逻辑关联 smt_package_types.Id）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_equipment_package`(`EquipmentTypeId` ASC, `PackageTypeId` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  INDEX `idx_package_type`(`PackageTypeId` ASC) USING BTREE,
  CONSTRAINT `fk_equip_pkg_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_equip_pkg_package_type` FOREIGN KEY (`PackageTypeId`) REFERENCES `smt_package_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 36 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '设备类型与封装类型匹配表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 9019 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'SMT设备类型字典' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '功能模块表（系统可授权的功能模块定义）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = 'SMT产线主数据' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_loading_records
-- ----------------------------
DROP TABLE IF EXISTS `smt_loading_records`;
CREATE TABLE `smt_loading_records`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `LotId` bigint NOT NULL COMMENT '批次ID（逻辑关联 smt_lots.Id）',
  `StationId` bigint NOT NULL COMMENT '工站ID（逻辑关联 smt_stations.Id，通过工站定位工序和设备）',
  `MaterialLotId` bigint NOT NULL COMMENT '物料批次ID（逻辑关联 smt_material_lots.Id，扫码物料批次条码）',
  `OperatorId` bigint NOT NULL COMMENT '上料操作员ID（逻辑关联 smt_users.Id）',
  `LoadingTime` datetime NULL DEFAULT NULL COMMENT '上料时间',
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
  INDEX `idx_operator`(`OperatorId` ASC) USING BTREE,
  INDEX `idx_station`(`StationId` ASC) USING BTREE,
  INDEX `idx_material_lot`(`MaterialLotId` ASC) USING BTREE,
  CONSTRAINT `fk_loading_lot` FOREIGN KEY (`LotId`) REFERENCES `smt_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_material_lot` FOREIGN KEY (`MaterialLotId`) REFERENCES `smt_material_lots` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_operator` FOREIGN KEY (`OperatorId`) REFERENCES `smt_users` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_loading_station` FOREIGN KEY (`StationId`) REFERENCES `smt_stations` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '上料记录表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 82 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '批次工序状态表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 39 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '批次表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_material_lots
-- ----------------------------
DROP TABLE IF EXISTS `smt_material_lots`;
CREATE TABLE `smt_material_lots`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `MaterialCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料编码（逻辑关联 smt_materials.MaterialCode）',
  `BatchNo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料批次号（业务唯一，日期+流水号）',
  `Supplier` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '供应商',
  `SupplierBatchNo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '供应商批次号',
  `Quantity` int NOT NULL COMMENT '批次数量',
  `ProductionDate` date NULL DEFAULT NULL COMMENT '生产日期',
  `ExpiryDate` date NULL DEFAULT NULL COMMENT '有效期（锡膏等有有效期）',
  `MslLevel` int NULL DEFAULT NULL COMMENT 'MSD湿敏等级（IC类物料用）',
  `InboundDate` datetime(3) NOT NULL COMMENT '入库日期',
  `Status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '在库' COMMENT '批次状态: 在库/已使用/已冻结/已报废',
  `Barcode` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '条码（系统自动生成，物料编码+物料批次号）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_material_lot_batch`(`MaterialCode` ASC, `BatchNo` ASC) USING BTREE,
  UNIQUE INDEX `uq_material_lot_barcode`(`Barcode` ASC) USING BTREE,
  INDEX `idx_material_code`(`MaterialCode` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  INDEX `idx_inbound_date`(`InboundDate` ASC) USING BTREE,
  CONSTRAINT `fk_material_lot_material` FOREIGN KEY (`MaterialCode`) REFERENCES `smt_materials` (`MaterialCode`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '物料批次表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '替代料关系表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '物料类型字典' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_materials
-- ----------------------------
DROP TABLE IF EXISTS `smt_materials`;
CREATE TABLE `smt_materials`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `MaterialCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '元件料号（业务唯一）',
  `MaterialDesc` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '物料描述',
  `MaterialTypeId` bigint NOT NULL COMMENT '物料类型ID（逻辑关联 smt_material_types.Id）',
  `PackageTypeId` bigint NOT NULL COMMENT '封装类型ID（逻辑关联 smt_package_types.Id）',
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
  INDEX `idx_package_type`(`PackageTypeId` ASC) USING BTREE,
  CONSTRAINT `fk_material_material_type` FOREIGN KEY (`MaterialTypeId`) REFERENCES `smt_material_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_material_package_type` FOREIGN KEY (`PackageTypeId`) REFERENCES `smt_package_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '物料主数据' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_operations
-- ----------------------------
DROP TABLE IF EXISTS `smt_operations`;
CREATE TABLE `smt_operations`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `OperationCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工序代码（业务唯一，如 PRINTER, SPI, REFLOW, AOI）',
  `OperationName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工序名称（如\"锡膏印刷\"\"SPI检测\"\"回流焊接\"）',
  `Description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '工序描述/补充说明',
  `StationId` bigint NULL DEFAULT NULL COMMENT '工站ID（逻辑关联 smt_stations.Id，工序与工站一对一）',
  `EquipmentTypeId` bigint NOT NULL COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id，从 smt_route_steps 迁移而来）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人（工艺工程师账号）',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_operation_code`(`OperationCode` ASC) USING BTREE COMMENT '工序代码全局唯一',
  INDEX `idx_operation_name`(`OperationName` ASC) USING BTREE COMMENT '按工序名称模糊查询',
  INDEX `idx_station`(`StationId` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  CONSTRAINT `fk_operation_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_operation_station` FOREIGN KEY (`StationId`) REFERENCES `smt_stations` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 35 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工序字典表（SMT工序标准定义）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_package_types
-- ----------------------------
DROP TABLE IF EXISTS `smt_package_types`;
CREATE TABLE `smt_package_types`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `PackageCode` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '封装编码（业务唯一，如 0201、0402、QFP、BGA）',
  `PackageName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '封装名称',
  `Category` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '封装分类（如 Chip/IC/Connector/Mechanical），用于快速筛选和统计',
  `SizeLength` decimal(10, 3) NULL DEFAULT NULL COMMENT '封装长度（mm）',
  `SizeWidth` decimal(10, 3) NULL DEFAULT NULL COMMENT '封装宽度（mm）',
  `SizeHeight` decimal(10, 3) NULL DEFAULT NULL COMMENT '封装高度（mm）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_package_code`(`PackageCode` ASC) USING BTREE,
  INDEX `idx_package_name`(`PackageName` ASC) USING BTREE,
  INDEX `idx_category`(`Category` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '封装类型字典' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_parameter_templates
-- ----------------------------
DROP TABLE IF EXISTS `smt_parameter_templates`;
CREATE TABLE `smt_parameter_templates`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TemplateCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板编码（业务唯一）',
  `TemplateName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '模板名称',
  `EquipmentTypeId` bigint NOT NULL COMMENT '适用设备类型ID（逻辑关联 smt_equipment_types.Id）',
  `Version` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'V1.0' COMMENT '版本号（系统自动生成，按设备类型递增，格式 V001/V002/V003...）',
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
  UNIQUE INDEX `uq_template_equipment_version`(`EquipmentTypeId` ASC, `Version` ASC) USING BTREE,
  INDEX `idx_equipment_type`(`EquipmentTypeId` ASC) USING BTREE,
  INDEX `idx_status`(`Status` ASC) USING BTREE,
  CONSTRAINT `fk_param_template_equipment_type` FOREIGN KEY (`EquipmentTypeId`) REFERENCES `smt_equipment_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 26 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工艺参数模板主表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_printer_parameter_items
-- ----------------------------
DROP TABLE IF EXISTS `smt_printer_parameter_items`;
CREATE TABLE `smt_printer_parameter_items`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `TemplateId` bigint NOT NULL COMMENT '所属模板ID（逻辑关联 smt_parameter_templates.Id）',
  `Pressure` decimal(10, 2) NULL DEFAULT NULL COMMENT '印刷压力(kg)',
  `Speed` decimal(10, 2) NULL DEFAULT NULL COMMENT '印刷速度(mm/s)',
  `SeparationSpeed` decimal(10, 2) NULL DEFAULT NULL COMMENT '分离速度(mm/s)',
  `SqueegeeAngle` int NULL DEFAULT NULL COMMENT '刮刀角度(度)',
  `CleanFrequency` int NULL DEFAULT NULL COMMENT '清洗频率(片/次)',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_template_printer`(`TemplateId` ASC) USING BTREE COMMENT '一个模板对应一条印刷机参数记录',
  CONSTRAINT `fk_printer_param_template` FOREIGN KEY (`TemplateId`) REFERENCES `smt_parameter_templates` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '锡膏印刷机参数明细表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_product_routes
-- ----------------------------
DROP TABLE IF EXISTS `smt_product_routes`;
CREATE TABLE `smt_product_routes`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `ProductId` bigint NOT NULL COMMENT '产品ID（逻辑关联 smt_products.Id）',
  `RouteId` bigint NOT NULL COMMENT '工艺路线ID（逻辑关联 smt_routes.Id）',
  `IsDefault` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否默认路线: 0-否, 1-是（同一产品最多一条默认路线，应用层控制）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_product_route`(`ProductId` ASC, `RouteId` ASC) USING BTREE COMMENT '同一产品与同一路线只关联一次',
  INDEX `idx_product`(`ProductId` ASC) USING BTREE COMMENT '按产品查关联路线',
  INDEX `idx_route`(`RouteId` ASC) USING BTREE COMMENT '按路线查关联产品',
  CONSTRAINT `fk_product_route_product` FOREIGN KEY (`ProductId`) REFERENCES `smt_products` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_product_route_route` FOREIGN KEY (`RouteId`) REFERENCES `smt_routes` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '产品-工艺路线关联表（产品与工艺路线的多对多关系）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '产品类型字典' ROW_FORMAT = DYNAMIC;

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
  CONSTRAINT `fk_product_product_type` FOREIGN KEY (`ProductTypeId`) REFERENCES `smt_product_types` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_aoi_threshold` CHECK (`AoiThreshold` between 0 and 100),
  CONSTRAINT `chk_spi_threshold` CHECK (`SpiThreshold` between 0 and 100)
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '产品主数据' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '维修记录表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 70 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色-功能关联表（角色与功能模块的多对多关系）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色表（系统角色的定义）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_route_steps
-- ----------------------------
DROP TABLE IF EXISTS `smt_route_steps`;
CREATE TABLE `smt_route_steps`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `RouteId` bigint NOT NULL COMMENT '工艺路线ID（逻辑关联 smt_routes.Id）',
  `OperationId` bigint NOT NULL COMMENT '工序ID（逻辑关联 smt_operations.Id）',
  `Sequence` int NOT NULL COMMENT '工序序号（10,20,30...）',
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
  INDEX `idx_parameter_template`(`ParameterTemplateId` ASC) USING BTREE,
  CONSTRAINT `fk_route_step_operation` FOREIGN KEY (`OperationId`) REFERENCES `smt_operations` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_route_step_route` FOREIGN KEY (`RouteId`) REFERENCES `smt_routes` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 48 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工艺路线工序关系表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工艺路线主表（SMT工艺路线定义）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 61 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '进站记录表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 52 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '出站记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for smt_stations
-- ----------------------------
DROP TABLE IF EXISTS `smt_stations`;
CREATE TABLE `smt_stations`  (
  `Id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `StationCode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工站编码（业务唯一）',
  `StationName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '工站名称',
  `DeviceId` bigint NOT NULL COMMENT '设备ID（逻辑关联 smt_equipment.Id，一对一绑定具体设备）',
  `LineId` bigint NULL DEFAULT NULL COMMENT '产线ID（逻辑关联 smt_lines.Id）',
  `StationOrder` int NULL DEFAULT NULL COMMENT '产线内顺序（同一产线内工站的排列序号）',
  `CreatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  `CreatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  `UpdatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
  `UpdatedBy` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '最后修改人',
  `IsDeleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '软删除: 0-正常, 1-已删除',
  `LastOperationType` tinyint NOT NULL DEFAULT 1 COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
  `LastOperationRemark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '最后操作备注',
  PRIMARY KEY (`Id`) USING BTREE,
  UNIQUE INDEX `uq_station_code`(`StationCode` ASC) USING BTREE,
  INDEX `idx_device`(`DeviceId` ASC) USING BTREE,
  INDEX `idx_line`(`LineId` ASC) USING BTREE,
  INDEX `idx_station_name`(`StationName` ASC) USING BTREE,
  CONSTRAINT `fk_station_device` FOREIGN KEY (`DeviceId`) REFERENCES `smt_equipment` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_station_line` FOREIGN KEY (`LineId`) REFERENCES `smt_lines` (`Id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 51 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工站表（产线物理位置）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '下料记录表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 34 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户-角色关联表（用户与角色的多对多关系）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 49 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '系统用户表（MES所有登录用户的基础信息）' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 56 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工单表' ROW_FORMAT = DYNAMIC;

SET FOREIGN_KEY_CHECKS = 1;
