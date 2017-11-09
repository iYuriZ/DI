<?php

if(!isset($_GET['balienummer']) || !isset($_GET['vluchtnummer']) || !isset($_GET['passagiernummer']) || !isset($_GET['objectnummer'])) {
    header('Location: /index.php');
}

require_once 'database.php';

$db = connectDatabase();
$stmt = $db->prepare('DELETE FROM Object WHERE volgnummer = ?');
$stmt->execute([
    $_GET['objectnummer']
]);

header('Location: /passagier.php?balienummer='.$_GET['balienummer'].'&vluchtnummer='.$_GET['vluchtnummer'].'&passagiernummer='.$_GET['passagiernummer']);