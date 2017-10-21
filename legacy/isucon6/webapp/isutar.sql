-- MySQL dump 10.13  Distrib 5.7.15, for Linux (x86_64)
--
-- Host: localhost    Database: isutar
-- ------------------------------------------------------
-- Server version	5.7.15-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `star`
--

DROP TABLE IF EXISTS `star`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `star` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `keyword` varchar(191) COLLATE utf8mb4_bin NOT NULL,
  `user_name` varchar(191) COLLATE utf8mb4_bin NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `star`
--

LOCK TABLES `star` WRITE;
/*!40000 ALTER TABLE `star` DISABLE KEYS */;
INSERT INTO `star` VALUES (1,'浦上則宗','mugifly','2016-09-17 10:44:02'),(2,'旦過駅','mugifly','2016-09-17 10:44:02'),(3,'境町 (群馬県)','mugifly','2016-09-17 10:44:03'),(4,'ソムデットチャオプラヤー','mugifly','2016-09-17 10:44:03'),(5,'354年','mugifly','2016-09-17 10:44:03'),(6,'122','mugifly','2016-09-17 10:44:04'),(7,'小出インターチェンジ','mugifly','2016-09-17 10:44:04'),(8,'毛利高翰','mugifly','2016-09-17 10:44:04'),(9,'紀元前419年','mugifly','2016-09-17 10:44:04'),(10,'埼玉県立滑川総合高等学校','mugifly','2016-09-17 10:44:05'),(11,'平尾山','sugmak','2016-09-17 10:44:19'),(12,'アルシーアル麻雀','sugmak','2016-09-17 10:44:23'),(13,'イギリス政府','akoba','2016-09-17 10:44:24'),(14,'平尾山','akoba','2016-09-17 10:44:32'),(15,'菅山かおる','masartz','2016-09-17 10:44:41'),(16,'南蟹谷村','masartz','2016-09-17 10:44:42'),(17,'トイズ','masartz','2016-09-17 10:44:45'),(18,'菅山かおる','arisawa','2016-09-17 10:44:48'),(19,'大阪市交通局南港ポートタウン線','masartz','2016-09-17 10:44:49'),(20,'井上敏夫','suenaga','2016-09-17 10:44:58'),(21,'船戸山','suenaga','2016-09-17 10:44:59'),(22,'CCE','suenaga','2016-09-17 10:44:59'),(23,'八田小学校','suenaga','2016-09-17 10:44:59'),(24,'ジョージ・ガモフ','suenaga','2016-09-17 10:45:00'),(25,'菅山かおる','suenaga','2016-09-17 10:45:01'),(26,'南蟹谷村','suenaga','2016-09-17 10:45:01'),(27,'トイズ','suenaga','2016-09-17 10:45:02'),(28,'大阪市交通局南港ポートタウン線','suenaga','2016-09-17 10:45:03'),(29,'イギリス政府','suenaga','2016-09-17 10:45:03'),(30,'井上敏夫','naoyuki','2016-09-17 10:45:03'),(31,'船戸山','naoyuki','2016-09-17 10:45:04'),(32,'CCE','naoyuki','2016-09-17 10:45:04'),(33,'八田小学校','naoyuki','2016-09-17 10:45:04');
/*!40000 ALTER TABLE `star` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-09-17 11:18:49
