<!doctype html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Home</title>
    <link rel="stylesheet" href="CSS/Style.css">
    <link rel="stylesheet" href="CSS/bootstrap.css">
</head>

<body>

<?php
    require 'functions/functions.php';

    $balies = getBalies();
?>

<div class="row main-container">
    <div class="col-md-4"></div>

    <main class="col-md-4">
        <h1>Balies</h1>

        <?php foreach ($balies as $balie) : ?>
            <a href="zoek.php" class="list-group-item"><?php echo $balie['balienummer']?></a>
        <?php endforeach; ?>
    </main>

    <div class="col-md-4"></div>
</div>

</body>

</html>
