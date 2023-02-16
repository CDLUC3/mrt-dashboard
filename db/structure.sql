
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `annita`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annita` (
  `xnum` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `annita_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annita_tbl` (
  `id` smallint NOT NULL DEFAULT '0',
  `number` int NOT NULL,
  `media_type` varchar(13) NOT NULL,
  `media_connectivity` varchar(7) NOT NULL,
  `access_mode` varchar(9) NOT NULL,
  `access_protocol` varchar(10) NOT NULL,
  `node_form` varchar(8) NOT NULL DEFAULT 'physical',
  `logical_volume` varchar(255) DEFAULT NULL,
  `external_provider` varchar(255) DEFAULT NULL,
  `verify_on_read` tinyint(1) NOT NULL,
  `verify_on_write` tinyint(1) NOT NULL,
  `base_url` varchar(2045) NOT NULL,
  `created` datetime NOT NULL,
  `source_node` smallint DEFAULT NULL,
  `target_node` smallint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_audits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_audits` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_node_id` smallint NOT NULL,
  `inv_object_id` int NOT NULL,
  `inv_version_id` int NOT NULL,
  `inv_file_id` int NOT NULL,
  `url` varchar(16383) DEFAULT NULL,
  `status` varchar(18) NOT NULL DEFAULT 'unknown',
  `created` datetime NOT NULL,
  `verified` datetime DEFAULT NULL,
  `modified` datetime DEFAULT NULL,
  `failed_size` bigint NOT NULL DEFAULT '0',
  `failed_digest_value` varchar(255) DEFAULT NULL,
  `note` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inv_node_id` (`inv_node_id`,`inv_version_id`,`inv_file_id`) USING BTREE,
  KEY `id_idx3` (`inv_file_id`) USING BTREE,
  KEY `id_idx` (`inv_node_id`) USING BTREE,
  KEY `id_idx1` (`inv_object_id`) USING BTREE,
  KEY `id_idx2` (`inv_version_id`) USING BTREE,
  KEY `status` (`status`) USING BTREE,
  KEY `verified` (`verified`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_collections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_collections` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int DEFAULT NULL,
  `ark` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `mnemonic` varchar(255) DEFAULT NULL,
  `read_privilege` varchar(10) DEFAULT NULL,
  `write_privilege` varchar(10) DEFAULT NULL,
  `download_privilege` varchar(10) DEFAULT NULL,
  `storage_tier` varchar(8) DEFAULT NULL,
  `harvest_privilege` varchar(6) NOT NULL DEFAULT 'none',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ark_UNIQUE` (`ark`) USING BTREE,
  KEY `id_hp` (`harvest_privilege`) USING BTREE,
  KEY `id_idx` (`inv_object_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_collections_inv_nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_collections_inv_nodes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_collection_id` smallint NOT NULL,
  `inv_node_id` smallint NOT NULL,
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inv_collection_id` (`inv_collection_id`,`inv_node_id`) USING BTREE,
  KEY `id_idx` (`inv_collection_id`) USING BTREE,
  KEY `id_idx1` (`inv_node_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_collections_inv_objects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_collections_inv_objects` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_collection_id` smallint NOT NULL,
  `inv_object_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_idx` (`inv_collection_id`) USING BTREE,
  KEY `id_idx1` (`inv_object_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_duas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_duas` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_collection_id` smallint DEFAULT NULL,
  `inv_object_id` int NOT NULL,
  `identifier` varchar(255) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `terms` varchar(16383) NOT NULL,
  `template` text,
  `accept_obligation` varchar(8) NOT NULL,
  `name_obligation` varchar(8) NOT NULL,
  `affiliation_obligation` varchar(8) NOT NULL,
  `email_obligation` varchar(8) NOT NULL,
  `applicability` varchar(10) NOT NULL,
  `persistence` varchar(9) NOT NULL,
  `notification` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`) USING BTREE,
  KEY `id_idx` (`inv_collection_id`) USING BTREE,
  KEY `id_idx1` (`inv_object_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_dublinkernels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_dublinkernels` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int NOT NULL,
  `inv_version_id` int NOT NULL,
  `seq_num` smallint NOT NULL,
  `element` varchar(255) NOT NULL,
  `qualifier` varchar(255) DEFAULT NULL,
  `value` mediumtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_idx` (`inv_object_id`) USING BTREE,
  KEY `id_idx1` (`inv_version_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_embargoes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_embargoes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int NOT NULL,
  `embargo_end_date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inv_object_id_UNIQUE` (`inv_object_id`) USING BTREE,
  KEY `embargo_end_date` (`embargo_end_date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_files` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int NOT NULL,
  `inv_version_id` int NOT NULL,
  `pathname` longtext NOT NULL,
  `source` varchar(8) NOT NULL,
  `role` varchar(8) NOT NULL,
  `full_size` bigint NOT NULL DEFAULT '0',
  `billable_size` bigint NOT NULL DEFAULT '0',
  `mime_type` varchar(255) DEFAULT NULL,
  `digest_type` varchar(8) DEFAULT NULL,
  `digest_value` varchar(255) DEFAULT NULL,
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `created` (`created`) USING BTREE,
  KEY `id_idx1` (`inv_object_id`) USING BTREE,
  KEY `id_idx` (`inv_version_id`) USING BTREE,
  KEY `mime_type` (`mime_type`) USING BTREE,
  KEY `role` (`role`) USING BTREE,
  KEY `pathname` (`pathname`(768)),
  KEY `source` (`source`) USING BTREE1
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_ingests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_ingests` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int NOT NULL,
  `inv_version_id` int NOT NULL,
  `filename` varchar(255) NOT NULL,
  `ingest_type` varchar(26) NOT NULL,
  `profile` varchar(255) NOT NULL,
  `batch_id` varchar(255) NOT NULL,
  `job_id` varchar(255) NOT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `submitted` datetime NOT NULL,
  `storage_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `batch_id` (`batch_id`) USING BTREE,
  KEY `id_idx` (`inv_object_id`) USING BTREE,
  KEY `id_idx1` (`inv_version_id`) USING BTREE,
  KEY `profile` (`profile`) USING BTREE,
  KEY `submitted` (`submitted`) USING BTREE,
  KEY `user_agent` (`user_agent`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_localids`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_localids` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_ark` varchar(255) NOT NULL,
  `inv_owner_ark` varchar(255) NOT NULL,
  `local_id` varchar(255) NOT NULL,
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `loc_unique` (`inv_owner_ark`,`local_id`) USING BTREE,
  KEY `id_idoba` (`inv_object_ark`) USING BTREE,
  KEY `id_idowa` (`inv_owner_ark`) USING BTREE,
  KEY `id_idloc` (`local_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_metadatas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_metadatas` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int NOT NULL,
  `inv_version_id` int NOT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `md_schema` varchar(14) NOT NULL,
  `version` varchar(255) DEFAULT NULL,
  `serialization` varchar(4) DEFAULT NULL,
  `value` mediumtext,
  PRIMARY KEY (`id`),
  KEY `id_idx` (`inv_object_id`) USING BTREE,
  KEY `id_idx1` (`inv_version_id`) USING BTREE,
  KEY `id_metax` (`version`(191)) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_nodes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `number` int NOT NULL,
  `media_type` varchar(13) NOT NULL,
  `media_connectivity` varchar(7) NOT NULL,
  `access_mode` varchar(9) NOT NULL,
  `access_protocol` varchar(10) NOT NULL,
  `node_form` varchar(8) NOT NULL DEFAULT 'virtual',
  `node_protocol` varchar(4) NOT NULL DEFAULT 'file',
  `logical_volume` varchar(255) DEFAULT NULL,
  `external_provider` varchar(255) DEFAULT NULL,
  `verify_on_read` tinyint(1) NOT NULL,
  `verify_on_write` tinyint(1) NOT NULL,
  `base_url` varchar(2045) NOT NULL,
  `created` datetime NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `source_node` smallint DEFAULT NULL,
  `target_node` smallint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_nodes_inv_objects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_nodes_inv_objects` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_node_id` smallint NOT NULL,
  `inv_object_id` int NOT NULL,
  `role` varchar(9) NOT NULL,
  `created` datetime NOT NULL,
  `replicated` datetime DEFAULT NULL,
  `version_number` smallint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `inv_object_id` (`inv_object_id`,`inv_node_id`) USING BTREE,
  KEY `id_idx` (`inv_node_id`) USING BTREE,
  KEY `id_idx1` (`inv_object_id`) USING BTREE,
  KEY `id_idx2` (`replicated`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_objects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_objects` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_owner_id` smallint NOT NULL,
  `ark` varchar(255) NOT NULL,
  `md5_3` varchar(3) DEFAULT NULL,
  `object_type` varchar(14) NOT NULL,
  `role` varchar(11) NOT NULL,
  `aggregate_role` varchar(27) DEFAULT NULL,
  `version_number` smallint NOT NULL,
  `erc_who` mediumtext,
  `erc_what` mediumtext,
  `erc_when` mediumtext,
  `erc_where` mediumtext,
  `created` datetime NOT NULL,
  `modified` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ark_UNIQUE` (`ark`(190)) USING BTREE,
  KEY `created` (`created`) USING BTREE,
  KEY `id_idx` (`inv_owner_id`) USING BTREE,
  KEY `modified` (`modified`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_owners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_owners` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int DEFAULT NULL,
  `ark` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ark_UNIQUE` (`ark`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inv_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inv_versions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `inv_object_id` int NOT NULL,
  `ark` varchar(255) NOT NULL,
  `number` smallint NOT NULL,
  `note` varchar(16383) DEFAULT NULL,
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ark` (`ark`) USING BTREE,
  KEY `created` (`created`) USING BTREE,
  KEY `id_idx` (`inv_object_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sha_dublinkernels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sha_dublinkernels` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `value` mediumtext NOT NULL,
  PRIMARY KEY (`id`),
  FULLTEXT KEY `value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO `schema_migrations` (version) VALUES
('0');


